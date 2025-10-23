package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io/fs"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"
)

/*
Neo4j Usage Exporter

This tool scans a Go codebase to extract and organize Neo4j/neogo database usage patterns.
It generates context files for AI code assistants and documentation purposes.

What it does:
1. Extracts code blocks containing Neo4j operations (.Exec, .Run, .Cypher, etc.)
2. Collects all edge definitions (edges.go files) into a single file
3. Collects all entity definitions (entity.go files) into a single file
4. Exports complete API directory contents organized by subdirectory
5. Fetches and formats the Neo4j database schema from Kubernetes pods

Output files:
- *_impl.txt: Neo4j usage blocks grouped by internal/ subdirectories
- all_edges.txt: All edge relationship definitions
- all_entities.txt: All entity/node definitions
- *_api.txt: Complete contents of each API subdirectory
- neo4j_database_schema_*.txt: Pretty-printed JSON database schema

The tool intelligently expands code blocks by:
- Tracking brace balance to capture complete function/method calls
- Handling Go string literals (backticks for raw strings, double quotes)
- Detecting comment boundaries
- Limiting block length to prevent over-extraction

Usage:
  neo4j_usage_export [--export OUTPUT_DIR] <resources|learning>

Example:
  neo4j_usage_export --export ./exports resources
*/

type ExportConfig struct {
	Root               string
	OutputFolder       string
	APIRoot            string
	IgnoredDirectories []string
	NeogoMarkers       []string
	BlockPatterns      []string
	MaxBlockLength     int
}

func NewExportConfig() *ExportConfig {
	return &ExportConfig{
		Root:         ".",
		OutputFolder: "exports",
		APIRoot:      "api",
		IgnoredDirectories: []string{
			"node_modules",
			"vendor",
			"neo4j",
			"dist",
		},
		NeogoMarkers: []string{
			"github.com/rlch/neogo",
			"github.com/rlch/neogo/db",
			"github.com/rlch/neogo/query",
			"github.com/MathGaps/neo4j-tooling",
			"github.com/MathGaps/neo4j-tooling/v2",
			"github.com/MathGaps/neo4j-tooling/v2/pkg/neo4jclient",
			"github.com/MathGaps/neo4j-tooling/v2/pkg/data/operations",
			"github.com/MathGaps/neo4j-tooling/v2/pkg/data/repositoryimpl",
			"github.com/MathGaps/neo4j-tooling/v2/pkg/domain",
			"github.com/neo4j/neo4j-go-driver/v5/neo4j",
			"neo4jclient.Execute",
			"query.Query",
		},
		BlockPatterns: []string{
			".Exec(",
			".ReadSession(",
			".WriteSession(",
			".ReadTransaction(",
			".WriteTransaction(",
			".RunWithParams(",
			".Run(ctx",
			".Run(",
			".Cypher(",
			"begin().",
		},
		MaxBlockLength: 40,
	}
}

const (
	NAMESPACE                = "learning"
	NEO4J_USER               = "neo4j"
	NEO4J_PASSWORD           = "De0YFd4XG239RCoP"
	SCHEMA_QUERY             = "CALL apoc.meta.schema() YIELD value RETURN apoc.convert.toJson(value) AS schema"
	SCHEMA_FILENAME_TEMPLATE = "neo4j_database_schema_%s.txt"
)

var VALID_POD_PREFIXES = map[string]bool{
	"resources": true,
	"learning":  true,
}

var cypherLineIndicators = []string{
	" MATCH ",
	"MATCH (",
	"OPTIONAL MATCH",
	"UNWIND ",
	"FOREACH ",
	"MERGE ",
	"MERGE(",
	"CALL ",
	"CALL{",
	"CALL(",
	"RETURN ",
	"CREATE ",
	"DETACH DELETE",
	"DELETE ",
	"SET ",
	"YIELD ",
	"APOC.",
	"apoc.",
}

var cypherContentIndicators = []string{
	"MATCH ",
	"MERGE ",
	"CALL ",
	"UNWIND ",
	"RETURN ",
	"CREATE ",
	"DETACH DELETE",
	"DELETE ",
	"FOREACH ",
	"SET ",
	"YIELD ",
	"apoc.",
	"neo4jclient.ExecuteRead",
	"neo4jclient.ExecuteWrite",
	"ManagedTransaction",
}

type Neo4jUsageExporter struct {
	config       *ExportConfig
	root         string
	outputFolder string
	apiRoot      string
}

func NewNeo4jUsageExporter(config *ExportConfig) (*Neo4jUsageExporter, error) {
	root, err := filepath.Abs(config.Root)
	if err != nil {
		return nil, err
	}

	var outputFolder string
	if filepath.IsAbs(config.OutputFolder) {
		outputFolder = config.OutputFolder
	} else {
		outputFolder = filepath.Join(root, config.OutputFolder)
	}

	if err := os.MkdirAll(outputFolder, 0755); err != nil {
		return nil, err
	}

	var apiRoot string
	if filepath.IsAbs(config.APIRoot) {
		apiRoot = config.APIRoot
	} else {
		apiRoot = filepath.Join(root, config.APIRoot)
	}

	return &Neo4jUsageExporter{
		config:       config,
		root:         root,
		outputFolder: outputFolder,
		apiRoot:      apiRoot,
	}, nil
}

func (e *Neo4jUsageExporter) Run() error {
	if err := e.exportNeogoUsage(); err != nil {
		return err
	}
	if err := e.exportAPISubfolders(); err != nil {
		return err
	}
	return nil
}

func (e *Neo4jUsageExporter) exportNeogoUsage() error {
	groupedBlocks := make(map[string][]string)
	var edgesContent []string
	var entitiesContent []string

	err := e.walkSourceTree(e.root, func(path, relativePath string) error {
		key := e.twoFolderKey(relativePath)
		if _, exists := groupedBlocks[key]; !exists {
			groupedBlocks[key] = []string{}
		}

		baseName := filepath.Base(path)
		parentName := filepath.Base(filepath.Dir(path))

		if baseName == "edges.go" || parentName == "edges" {
			content, err := e.readFullFile(path, relativePath)
			if err == nil && content != "" {
				edgesContent = append(edgesContent, content)
			}
			return nil
		}

		if baseName == "entity.go" {
			content, err := e.readFullFile(path, relativePath)
			if err == nil && content != "" {
				entitiesContent = append(entitiesContent, content)
			}
			return nil
		}

		blocks, err := e.collectBlocks(path, relativePath)
		if err == nil && len(blocks) > 0 {
			groupedBlocks[key] = append(groupedBlocks[key], blocks...)
		}

		return nil
	})
	if err != nil {
		return err
	}

	for key, blocks := range groupedBlocks {
		if len(blocks) == 0 {
			continue
		}
		outputName := e.neogoOutputName(key)
		outputFile := filepath.Join(e.outputFolder, outputName)
		if err := os.WriteFile(outputFile, []byte(strings.Join(blocks, "")), 0644); err != nil {
			return err
		}
	}

	if len(edgesContent) > 0 {
		outputFile := filepath.Join(e.outputFolder, "all_edges.txt")
		if err := os.WriteFile(outputFile, []byte(strings.Join(edgesContent, "")), 0644); err != nil {
			return err
		}
	}

	if len(entitiesContent) > 0 {
		outputFile := filepath.Join(e.outputFolder, "all_entities.txt")
		if err := os.WriteFile(outputFile, []byte(strings.Join(entitiesContent, "")), 0644); err != nil {
			return err
		}
	}

	return nil
}

func (e *Neo4jUsageExporter) collectBlocks(path, relativePath string) ([]string, error) {
	content, err := os.ReadFile(path)
	if err != nil {
		return nil, nil
	}

	ext := filepath.Ext(path)
	if ext == ".py" {
		return nil, nil
	}

	contentStr := string(content)
	switch ext {
	case ".go":
		if !e.usesNeogo(contentStr) && !containsCypherIndicators(contentStr) {
			return nil, nil
		}
	case ".cypher":
		// always include cypher scripts
	default:
		if !containsCypherIndicators(contentStr) {
			return nil, nil
		}
	}

	lines := strings.Split(contentStr, "\n")
	var matches []int
	for idx, line := range lines {
		if e.lineHasPattern(line) {
			matches = append(matches, idx)
		}
	}

	if len(matches) == 0 {
		return nil, nil
	}

	var blocks []string
	seenLines := make(map[int]bool)

	for _, idx := range matches {
		if seenLines[idx] {
			continue
		}

		start, end := e.expandBlock(lines, idx)

		overlaps := false
		for i := start; i <= end; i++ {
			if seenLines[i] {
				overlaps = true
				break
			}
		}
		if overlaps {
			continue
		}

		var blockLines []string
		for i := start; i <= end; i++ {
			blockLines = append(blockLines, lines[i])
		}

		block := fmt.Sprintf("// %s:%d-%d\n%s\n", relativePath, start+1, end+1, strings.Join(blockLines, "\n"))
		blocks = append(blocks, block)

		for i := start; i <= end; i++ {
			seenLines[i] = true
		}
	}

	return blocks, nil
}

func (e *Neo4jUsageExporter) expandBlock(lines []string, idx int) (int, int) {
	start := idx
	for start > 0 && strings.TrimSpace(lines[start-1]) != "" {
		start--
	}

	insideRaw := false
	insideDouble := false
	braceBalance := 0
	end := idx

	for offset := start; offset < len(lines); offset++ {
		line := lines[offset]
		newInsideRaw, newInsideDouble, delta := e.scanLineState(line, insideRaw, insideDouble)
		insideRaw = newInsideRaw
		insideDouble = newInsideDouble
		braceBalance += delta
		end = offset

		var nextLine string
		if offset+1 < len(lines) {
			nextLine = lines[offset+1]
		}

		reachedMatch := offset >= idx
		boundary := strings.TrimSpace(nextLine) == ""
		balanceReset := braceBalance <= 0
		lengthExceeded := (end - start + 1) >= e.config.MaxBlockLength

		if !insideRaw && !insideDouble {
			if reachedMatch && (boundary || balanceReset || lengthExceeded) {
				break
			}
		}
	}

	return start, end
}

func (e *Neo4jUsageExporter) scanLineState(line string, insideRaw, insideDouble bool) (bool, bool, int) {
	braceDelta := 0
	runes := []rune(line)

	for i := 0; i < len(runes); i++ {
		ch := runes[i]

		if !insideRaw && !insideDouble && ch == '/' && i+1 < len(runes) && runes[i+1] == '/' {
			break
		}

		if ch == '`' && !insideDouble {
			insideRaw = !insideRaw
			continue
		}

		if ch == '"' && !insideRaw {
			escaped := i > 0 && runes[i-1] == '\\'
			if !escaped {
				insideDouble = !insideDouble
			}
			continue
		}

		if !insideRaw && !insideDouble {
			if ch == '{' {
				braceDelta++
			} else if ch == '}' {
				braceDelta--
			}
		}
	}

	return insideRaw, insideDouble, braceDelta
}

func (e *Neo4jUsageExporter) lineHasPattern(line string) bool {
	stripped := strings.TrimSpace(line)
	if stripped == "" || strings.HasPrefix(stripped, "//") {
		return false
	}
	for _, pattern := range e.config.BlockPatterns {
		if strings.Contains(line, pattern) {
			return true
		}
	}
	return isCypherLine(stripped)
}

func containsCypherIndicators(text string) bool {
	for _, indicator := range cypherContentIndicators {
		if strings.Contains(text, indicator) {
			return true
		}
	}
	return false
}

func isCypherLine(line string) bool {
	for _, indicator := range cypherLineIndicators {
		if strings.Contains(line, indicator) {
			return true
		}
	}
	return false
}

func (e *Neo4jUsageExporter) usesNeogo(content string) bool {
	for _, marker := range e.config.NeogoMarkers {
		if strings.Contains(content, marker) {
			return true
		}
	}
	return false
}

func (e *Neo4jUsageExporter) twoFolderKey(relativePath string) string {
	parts := strings.Split(filepath.ToSlash(relativePath), "/")
	if len(parts) > 2 {
		return filepath.Join(parts[0], parts[1])
	}
	if len(parts) == 2 {
		return parts[0]
	}
	return "root"
}

func (e *Neo4jUsageExporter) walkSourceTree(directory string, fn func(path, relativePath string) error) error {
	ignoredSet := make(map[string]bool)
	for _, dir := range e.config.IgnoredDirectories {
		ignoredSet[dir] = true
	}
	ignoredSet[filepath.Base(e.outputFolder)] = true

	return filepath.WalkDir(directory, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return nil
		}

		if d.IsDir() && ignoredSet[d.Name()] {
			return fs.SkipDir
		}

		if !d.IsDir() {
			relPath, err := filepath.Rel(directory, path)
			if err != nil {
				return nil
			}
			return fn(path, filepath.ToSlash(relPath))
		}

		return nil
	})
}

func (e *Neo4jUsageExporter) readFullFile(path, relativePath string) (string, error) {
	content, err := os.ReadFile(path)
	if err != nil {
		return "", err
	}
	return fmt.Sprintf("// %s\n%s\n\n", relativePath, string(content)), nil
}

func (e *Neo4jUsageExporter) exportAPISubfolders() error {
	info, err := os.Stat(e.apiRoot)
	if err != nil || !info.IsDir() {
		return nil
	}

	entries, err := os.ReadDir(e.apiRoot)
	if err != nil {
		return nil
	}

	var dirNames []string
	for _, entry := range entries {
		if entry.IsDir() {
			dirNames = append(dirNames, entry.Name())
		}
	}
	sort.Strings(dirNames)

	for _, dirName := range dirNames {
		subdir := filepath.Join(e.apiRoot, dirName)
		contents, err := e.gatherAPIContents(subdir)
		if err != nil || len(contents) == 0 {
			continue
		}

		outputFile := filepath.Join(e.outputFolder, dirName+"_api.txt")
		if err := os.WriteFile(outputFile, []byte(strings.Join(contents, "")), 0644); err != nil {
			return err
		}
	}

	return nil
}

func (e *Neo4jUsageExporter) gatherAPIContents(subdir string) ([]string, error) {
	var chunks []string
	var files []string

	err := filepath.WalkDir(subdir, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return nil
		}
		if !d.IsDir() {
			files = append(files, path)
		}
		return nil
	})
	if err != nil {
		return nil, err
	}

	sort.Strings(files)

	for _, file := range files {
		content, err := os.ReadFile(file)
		if err != nil {
			continue
		}

		relPath, err := filepath.Rel(e.root, file)
		if err != nil {
			continue
		}

		chunks = append(chunks, fmt.Sprintf("// %s\n%s\n", filepath.ToSlash(relPath), string(content)))
	}

	return chunks, nil
}

func (e *Neo4jUsageExporter) neogoOutputName(key string) string {
	normalized := filepath.ToSlash(key)
	if strings.HasPrefix(normalized, "internal/") {
		parts := strings.Split(normalized, "/")
		folder := "internal"
		if len(parts) > 1 {
			folder = parts[1]
		}
		return folder + "_impl.txt"
	}
	return strings.ReplaceAll(normalized, "/", "_") + ".txt"
}

func exportNeo4jSchema(target, outputFolder string) (string, error) {
	normalized := strings.ToLower(strings.TrimSpace(target))
	if !VALID_POD_PREFIXES[normalized] {
		return "", fmt.Errorf("target must be one of [learning resources]")
	}

	podName := fmt.Sprintf("%s-neo4j-1-0", normalized)
	cmd := exec.Command("kubectl", "exec", "-n", NAMESPACE, podName, "-c", "neo4j", "--",
		"cypher-shell", "--format", "plain", "-u", NEO4J_USER, "-p", NEO4J_PASSWORD, SCHEMA_QUERY)

	output, err := cmd.CombinedOutput()
	if err != nil {
		return "", fmt.Errorf(":: Schema export skipped due to error, other files have been exported: %s", strings.TrimSpace(string(output)))
	}

	if err := os.MkdirAll(outputFolder, 0755); err != nil {
		return "", err
	}

	outputPath := filepath.Join(outputFolder, fmt.Sprintf(SCHEMA_FILENAME_TEMPLATE, normalized))
	if err := postprocessSchemaOutput(string(output), outputPath); err != nil {
		return "", err
	}

	absPath, err := filepath.Abs(outputPath)
	if err != nil {
		return outputPath, nil
	}

	return absPath, nil
}

func postprocessSchemaOutput(rawOutput, outputPath string) error {
	lines := strings.Split(rawOutput, "\n")
	if len(lines) == 0 {
		return os.WriteFile(outputPath, []byte(""), 0644)
	}

	var dataLines []string
	for i := 1; i < len(lines); i++ {
		if strings.TrimSpace(lines[i]) != "" {
			dataLines = append(dataLines, lines[i])
		}
	}

	if len(dataLines) == 0 {
		return os.WriteFile(outputPath, []byte(""), 0644)
	}

	contentWithoutHeader := strings.TrimSpace(strings.Join(dataLines, "\n"))
	if contentWithoutHeader == "" {
		return os.WriteFile(outputPath, []byte(""), 0644)
	}

	jsonPayload, err := extractSchemaJSON(contentWithoutHeader)
	if err != nil {
		snippet := contentWithoutHeader
		if len(snippet) > 200 {
			snippet = snippet[:200]
		}
		snippet = strings.ReplaceAll(snippet, "\n", " ")
		return fmt.Errorf("Unexpected schema output format, cannot decode JSON: %s", snippet)
	}

	formatted, err := json.MarshalIndent(jsonPayload, "", "  ")
	if err != nil {
		return err
	}

	formattedStr := string(formatted)
	if !strings.HasSuffix(formattedStr, "\n") {
		formattedStr += "\n"
	}

	return os.WriteFile(outputPath, []byte(formattedStr), 0644)
}

func extractSchemaJSON(content string) (interface{}, error) {
	text := strings.TrimSpace(content)

	if strings.HasPrefix(text, `"`) && strings.HasSuffix(text, `"`) {
		var unquoted string
		if err := json.Unmarshal([]byte(text), &unquoted); err != nil {
			return nil, err
		}
		text = unquoted
	}

	var result interface{}
	if err := json.Unmarshal([]byte(text), &result); err != nil {
		return nil, err
	}

	return result, nil
}

func main() {
	exportDir := flag.String("export", "exports", "Export folder path")
	flag.Usage = func() {
		fmt.Fprintf(os.Stderr, "Usage: %s [OPTIONS] <resources|learning>\n\n", os.Args[0])
		fmt.Fprintf(os.Stderr, "Export Neo4j usage blocks and database schema\n\n")
		fmt.Fprintf(os.Stderr, "Arguments:\n")
		fmt.Fprintf(os.Stderr, "  target    Target Neo4j instance (resources or learning)\n\n")
		fmt.Fprintf(os.Stderr, "Options:\n")
		flag.PrintDefaults()
	}
	flag.Parse()

	args := flag.Args()
	if len(args) != 1 {
		flag.Usage()
		os.Exit(1)
	}

	target := args[0]

	config := NewExportConfig()
	config.OutputFolder = *exportDir

	exporter, err := NewNeo4jUsageExporter(config)
	if err != nil {
		fmt.Fprintf(os.Stderr, "%v\n", err)
		os.Exit(1)
	}

	if err := exporter.Run(); err != nil {
		fmt.Fprintf(os.Stderr, "%v\n", err)
		os.Exit(1)
	}

	schemaPath, err := exportNeo4jSchema(target, exporter.outputFolder)
	if err != nil {
		fmt.Fprintf(os.Stderr, "%v\n", err)
		os.Exit(1)
	}

	fmt.Printf("All extracted blocks and files saved to '%s'\n", exporter.outputFolder)
	fmt.Printf("Schema export saved to '%s'\n", schemaPath)
}
