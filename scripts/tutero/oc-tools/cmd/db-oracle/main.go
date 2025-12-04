package main

import (
	"context"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"

	"tutero/oc-tools/shared"
)

const usage = `Usage: db-oracle -db <resources|learning|teaching> [-s SESSION_ID] [-v] [--dirs <dir1> <dir2> ...]

Arguments:
  -db <name>        Database to query (required): resources, learning, or teaching
  -s SESSION_ID     Continue an existing session
  -v                Verbose mode (show logs location)
  --dirs <dirs...>  Additional directories to reference in the prompt
  --help, -h        Show this help message

Note: Prompt must be provided via stdin (pipe or redirect)

Examples:
  echo "List all courses" | db-oracle -db learning
  cat query.txt | db-oracle -db teaching
  cat prompt.txt | db-oracle -db resources --dirs backend/app frontend/src
  db-oracle -db resources -s ses_abc123 <<< "continue with the query"
`

func main() {
	// Isolate sessions from main opencode CLI
	shared.IsolateDataDir()

	var db string
	var sessionID string
	var verbose bool
	var showHelp bool

	flag.StringVar(&db, "db", "", "Database to query: resources, learning, or teaching")
	flag.StringVar(&sessionID, "s", "", "Continue an existing session")
	flag.StringVar(&sessionID, "session", "", "Continue an existing session")
	flag.BoolVar(&verbose, "v", false, "Verbose mode")
	flag.BoolVar(&showHelp, "help", false, "Show help")
	flag.BoolVar(&showHelp, "h", false, "Show help")

	// Custom parsing for --dirs which takes multiple values
	var dirs []string
	args := os.Args[1:]
	var filteredArgs []string

	for i := 0; i < len(args); i++ {
		if args[i] == "--dirs" {
			i++
			for i < len(args) && !strings.HasPrefix(args[i], "-") {
				dirs = append(dirs, args[i])
				i++
			}
			i-- // Back up one since the loop will increment
		} else {
			filteredArgs = append(filteredArgs, args[i])
		}
	}

	// Parse remaining flags
	flag.CommandLine.Parse(filteredArgs)

	if showHelp {
		fmt.Fprint(os.Stderr, usage)
		os.Exit(0)
	}

	if db == "" {
		repoName := getRepoName()
		fmt.Fprintf(os.Stderr, "Error: -db argument is required\n")
		fmt.Fprintf(os.Stderr, "Usage: echo \"prompt\" | db-oracle -db <resources|learning|teaching> [-s SESSION_ID] [-v] [--dirs <dir1> <dir2> ...]\n")
		fmt.Fprintf(os.Stderr, "Hint: You're currently in repo: '%s'\n", repoName)
		os.Exit(1)
	}

	validDBs := map[string]bool{"resources": true, "learning": true, "teaching": true}
	if !validDBs[db] {
		fmt.Fprintf(os.Stderr, "Error: -db must be one of: resources, learning, teaching\n")
		os.Exit(1)
	}

	// Check stdin
	stat, _ := os.Stdin.Stat()
	if (stat.Mode() & os.ModeCharDevice) != 0 {
		fmt.Fprintf(os.Stderr, "Error: Prompt must be provided via stdin (pipe or redirect)\n")
		fmt.Fprintf(os.Stderr, "Usage: echo \"prompt\" | db-oracle -db <resources|learning|teaching> [-s SESSION_ID] [-v] [--dirs <dir1> <dir2> ...]\n")
		os.Exit(1)
	}

	// Read prompt from stdin
	prompt, err := shared.ReadStdinOrArgs(nil)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error reading prompt: %v\n", err)
		os.Exit(1)
	}

	// Build final prompt with dirs context
	var finalPrompt strings.Builder
	if len(dirs) > 0 {
		finalPrompt.WriteString("Referenced Project/Repositories directories:\n")
		for _, dir := range dirs {
			finalPrompt.WriteString(fmt.Sprintf("- %s\n", dir))
		}
		finalPrompt.WriteString("\n")
	}
	finalPrompt.WriteString(prompt)

	// Setup logging
	logFile, err := shared.SetupLogDir("db-oracle")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Warning: could not setup logging: %v\n", err)
	}

	// Run from metarepo
	workDir := filepath.Join(os.Getenv("HOME"), "Coding", "metarepo")

	// Create context with timeout (db-oracle can take very long due to opus model)
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Minute)
	defer cancel()

	client := shared.NewClient(ctx)
	defer client.Close()

	var result *shared.AgentResult

	if sessionID != "" {
		// Continue existing session
		result, err = client.ContinueSession(sessionID, "db-oracle", finalPrompt.String(), workDir)
	} else {
		// Start new session
		result, err = client.RunAgent("db-oracle", finalPrompt.String(), workDir)
	}

	if err != nil {
		errMsg := fmt.Sprintf("Error: %v\n", err)
		if logFile != "" {
			shared.WriteLog(logFile, errMsg)
		}
		fmt.Fprint(os.Stderr, errMsg)
		os.Exit(1)
	}

	// Log output with session ID for follow-up
	if logFile != "" {
		shared.WriteLogWithSession(logFile, result.Output, result.SessionID)
		if verbose {
			fmt.Fprintf(os.Stderr, "[debug] Logs saved to: %s\n", logFile)
		}
	}

	// Print output
	fmt.Println(result.Output)

	// Print session follow-up instructions
	shared.PrintSessionFollowUp("db-oracle", result.SessionID)
}

func getRepoName() string {
	wd, err := os.Getwd()
	if err != nil {
		return "unknown"
	}
	return filepath.Base(wd)
}
