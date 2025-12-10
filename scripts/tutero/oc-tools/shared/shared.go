package shared

import (
	"bufio"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
	"sync"
	"time"

	"github.com/sst/opencode-sdk-go"
	"github.com/sst/opencode-sdk-go/option"
)

const (
	DefaultHostname = "localhost" // Use localhost, not 127.0.0.1 - avoids Cloudflare tunnel routing issues
	DefaultPort     = 4096
	IsolatedPort    = 4097        // Separate port for SDK tools with isolated data
	DefaultTimeout  = 10 * time.Minute
)

// IsolateDataDir sets XDG_DATA_HOME and uses separate port to isolate SDK tool sessions
// Sessions will be stored in ~/.cache/scripts/opencode-data/ instead of ~/.local/share/opencode/
// This prevents SDK tool sessions from polluting the main session history
func IsolateDataDir() {
	isolatedDir := filepath.Join(os.Getenv("HOME"), ".cache", "scripts", "opencode-data")
	os.MkdirAll(isolatedDir, 0755)
	os.Setenv("XDG_DATA_HOME", isolatedDir)
	// Use isolated port so we get our own server with this XDG_DATA_HOME
	os.Setenv("OPENCODE_SDK_ISOLATED", "1")
}

// Client wraps opencode client with server lifecycle management
type Client struct {
	*opencode.Client
	ctx       context.Context
	serverCmd *exec.Cmd
	baseURL   string
	logger    *Logger
}

// NewClient creates opencode client, auto-starting server if needed (like TS SDK createOpencode)
func NewClient(ctx context.Context) *Client {
	return NewClientWithLogger(ctx, nil)
}

// NewClientWithLogger creates opencode client with a logger for realtime activity logging
func NewClientWithLogger(ctx context.Context, logger *Logger) *Client {
	baseURL := os.Getenv("OPENCODE_URL")
	if baseURL == "" {
		// Use isolated port if IsolateDataDir() was called
		port := DefaultPort
		if os.Getenv("OPENCODE_SDK_ISOLATED") == "1" {
			port = IsolatedPort
		}
		baseURL = fmt.Sprintf("http://%s:%d", DefaultHostname, port)
	}

	c := &Client{
		ctx:     ctx,
		baseURL: baseURL,
		logger:  logger,
	}

	c.log("Creating client with baseURL: %s", baseURL)
	c.log("Isolated mode: %v", os.Getenv("OPENCODE_SDK_ISOLATED") == "1")

	// Check if server is already running
	if !c.isServerRunning() {
		c.log("Server not running, starting...")
		// Start server subprocess (mimics TS SDK createOpencodeServer pattern)
		if url, err := c.startServer(); err != nil {
			c.log("ERROR: could not start server: %v", err)
			fmt.Fprintf(os.Stderr, "[opencode] Warning: could not start server: %v\n", err)
			fmt.Fprintf(os.Stderr, "[opencode] Ensure 'opencode' is installed and in PATH\n")
		} else {
			c.log("Server started at: %s", url)
			c.baseURL = url
		}
	} else {
		c.log("Server already running at: %s", baseURL)
	}

	c.Client = opencode.NewClient(
		option.WithBaseURL(c.baseURL),
	)
	c.log("SDK client initialized")

	return c
}

// log writes to the client's logger if available
func (c *Client) log(format string, args ...interface{}) {
	if c.logger != nil {
		c.logger.Log("[SDK] "+format, args...)
	}
}

// isServerRunning checks if opencode server is available
func (c *Client) isServerRunning() bool {
	client := &http.Client{Timeout: 2 * time.Second}
	resp, err := client.Get(c.baseURL + "/session")
	if err != nil {
		return false
	}
	resp.Body.Close()
	return resp.StatusCode == 200
}

// startServer spawns `opencode serve` and waits for startup message
// Mimics TS SDK's createOpencodeServer: parses "opencode server listening on http://..."
func (c *Client) startServer() (string, error) {
	// Use isolated port if set
	port := DefaultPort
	if os.Getenv("OPENCODE_SDK_ISOLATED") == "1" {
		port = IsolatedPort
	}

	cmd := exec.Command("opencode", "serve",
		fmt.Sprintf("--hostname=%s", DefaultHostname),
		fmt.Sprintf("--port=%d", port),
	)

	stdout, err := cmd.StdoutPipe()
	if err != nil {
		return "", fmt.Errorf("failed to get stdout pipe: %w", err)
	}

	// Discard stderr to prevent blocking (opencode logs go to stderr with --print-logs)
	cmd.Stderr = nil // goes to os.DevNull

	if err := cmd.Start(); err != nil {
		return "", fmt.Errorf("failed to start opencode serve: %w", err)
	}

	c.serverCmd = cmd

	// Parse stdout for: "opencode server listening on http://127.0.0.1:4096"
	urlRe := regexp.MustCompile(`listening on\s+(https?://[^\s]+)`)
	ready := make(chan string, 1)

	go func() {
		scanner := bufio.NewScanner(stdout)
		urlSent := false
		for scanner.Scan() {
			line := scanner.Text()
			if !urlSent {
				if matches := urlRe.FindStringSubmatch(line); len(matches) > 1 {
					ready <- matches[1]
					urlSent = true
					// Continue draining stdout to prevent pipe buffer from filling
				}
			}
			// Keep consuming stdout until EOF to prevent process blocking
		}
		if !urlSent {
			close(ready)
		}
	}()

	// Wait up to 30 seconds for server ready
	select {
	case url := <-ready:
		if url != "" {
			return url, nil
		}
		return "", fmt.Errorf("server did not report URL")
	case <-time.After(30 * time.Second):
		cmd.Process.Kill()
		return "", fmt.Errorf("server startup timeout")
	case <-c.ctx.Done():
		cmd.Process.Kill()
		return "", c.ctx.Err()
	}
}

// Close stops the server if we started it
func (c *Client) Close() {
	if c.serverCmd != nil && c.serverCmd.Process != nil {
		c.serverCmd.Process.Kill()
		c.serverCmd.Wait()
	}
}

// AgentResult contains the output and session info for follow-up
type AgentResult struct {
	Output    string
	SessionID string
}

// AgentOptions contains optional settings for agent calls
type AgentOptions struct {
	Tools       map[string]bool // Enable/disable specific tools (e.g., "websearch": true)
	Model       *ModelConfig    // Override model (provider + model ID)
	System      string          // System prompt (use instead of agent if set)
	NoAgent     bool            // If true, don't use agent field (use System instead)
	AutoCleanup bool            // If true, delete session after completion (prevents history pollution)
}

// ModelConfig specifies provider and model
type ModelConfig struct {
	ProviderID string
	ModelID    string
}

// FreeModel represents a free model from opencode provider
type FreeModel struct {
	ProviderID  string
	ModelID     string
	Name        string
	ReleaseDate string
	ToolCall    bool
}

// FindBestFreeModel queries opencode provider for the best free model
// Returns nil if no free models available
func (c *Client) FindBestFreeModel() (*FreeModel, error) {
	resp, err := c.App.Providers(c.ctx, opencode.AppProvidersParams{})
	if err != nil {
		return nil, fmt.Errorf("failed to get providers: %w", err)
	}

	var bestModel *FreeModel

	for _, provider := range resp.Providers {
		if provider.ID != "opencode" {
			continue
		}

		for modelID, model := range provider.Models {
			// Check if free (zero cost)
			if model.Cost.Input != 0 || model.Cost.Output != 0 {
				continue
			}

			// Skip only if tool_call is explicitly false
			// null or true means tool calls are supported
			if model.ToolCall == false && model.JSON.ToolCall.IsNull() == false {
				continue
			}

			candidate := &FreeModel{
				ProviderID:  "opencode",
				ModelID:     modelID,
				Name:        model.Name,
				ReleaseDate: model.ReleaseDate,
				ToolCall:    model.ToolCall,
			}

			// Pick the one with latest release date
			if bestModel == nil || candidate.ReleaseDate > bestModel.ReleaseDate {
				bestModel = candidate
			}
		}
	}

	return bestModel, nil
}

// RunAgent creates a session, sends prompt to agent, extracts text output
// Returns session ID for potential follow-up (session is NOT deleted)
func (c *Client) RunAgent(agentName, prompt, workDir string) (*AgentResult, error) {
	return c.RunAgentWithOptions(agentName, prompt, workDir, nil)
}

// RunAgentWithOptions creates a session with optional settings (tools, etc.)
func (c *Client) RunAgentWithOptions(agentName, prompt, workDir string, opts *AgentOptions) (*AgentResult, error) {
	c.log("RunAgent called: agent=%s, workDir=%s", agentName, workDir)
	c.log("Prompt length: %d chars", len(prompt))
	if len(prompt) < 2000 {
		c.log("Prompt content:\n%s", prompt)
	} else {
		c.log("Prompt content (first 2000 chars):\n%s...", prompt[:2000])
	}

	if opts != nil {
		c.log("Options: Tools=%v, NoAgent=%v, AutoCleanup=%v", opts.Tools, opts.NoAgent, opts.AutoCleanup)
		if opts.Model != nil {
			c.log("Model override: %s/%s", opts.Model.ProviderID, opts.Model.ModelID)
		}
		if opts.System != "" {
			c.log("System prompt length: %d", len(opts.System))
		}
	}

	// Create session
	c.log("Creating new session...")
	session, err := c.Session.New(c.ctx, opencode.SessionNewParams{
		Directory: opencode.F(workDir),
		Title:     opencode.F(fmt.Sprintf("%s-%d", agentName, time.Now().Unix())),
	})
	if err != nil {
		c.log("ERROR: failed to create session: %v", err)
		return nil, fmt.Errorf("failed to create session: %w", err)
	}

	sessionID := session.ID
	c.log("Session created: %s", sessionID)

	// Broadcast session ID early for timeout recovery
	fmt.Fprintf(os.Stderr, "\n────────────────────────────────────────────────────────────────\n")
	fmt.Fprintf(os.Stderr, "Session started: %s\n", sessionID)
	fmt.Fprintf(os.Stderr, "If timeout occurs, continue with: -s %s\n", sessionID)
	fmt.Fprintf(os.Stderr, "────────────────────────────────────────────────────────────────\n\n")

	// Build prompt params
	params := opencode.SessionPromptParams{
		Directory: opencode.F(workDir),
		Parts: opencode.F([]opencode.SessionPromptParamsPartUnion{
			opencode.TextPartInputParam{
				Type: opencode.F(opencode.TextPartInputTypeText),
				Text: opencode.F(prompt),
			},
		}),
	}

	// Use agent unless NoAgent is set
	if opts == nil || !opts.NoAgent {
		params.Agent = opencode.F(agentName)
	}

	// Add tools if specified
	if opts != nil && opts.Tools != nil {
		params.Tools = opencode.F(opts.Tools)
	}

	// Add model override if specified
	if opts != nil && opts.Model != nil {
		params.Model = opencode.F(opencode.SessionPromptParamsModel{
			ProviderID: opencode.F(opts.Model.ProviderID),
			ModelID:    opencode.F(opts.Model.ModelID),
		})
	}

	// Add system prompt if specified
	if opts != nil && opts.System != "" {
		params.System = opencode.F(opts.System)
	}

	// Send prompt to agent with directory context
	c.log("Sending prompt to session (this may take a while)...")
	startTime := time.Now()
	response, err := c.Session.Prompt(c.ctx, sessionID, params)
	elapsed := time.Since(startTime)

	if err != nil {
		c.log("ERROR: prompt failed after %v: %v", elapsed, err)
		return nil, fmt.Errorf("failed to send prompt: %w", err)
	}

	c.log("Prompt completed in %v", elapsed)
	c.log("Response parts count: %d", len(response.Parts))

	output := ExtractTextFromParts(response.Parts)
	c.log("Extracted text length: %d chars", len(output))
	if len(output) < 5000 {
		c.log("Response output:\n%s", output)
	} else {
		c.log("Response output (first 5000 chars):\n%s...", output[:5000])
	}

	return &AgentResult{
		Output:    output,
		SessionID: sessionID,
	}, nil
}

// ContinueSession sends a follow-up prompt to an existing session
func (c *Client) ContinueSession(sessionID, agentName, prompt, workDir string) (*AgentResult, error) {
	return c.ContinueSessionWithOptions(sessionID, agentName, prompt, workDir, nil)
}

// ContinueSessionWithOptions sends a follow-up prompt with optional settings
func (c *Client) ContinueSessionWithOptions(sessionID, agentName, prompt, workDir string, opts *AgentOptions) (*AgentResult, error) {
	c.log("ContinueSession called: sessionID=%s, agent=%s, workDir=%s", sessionID, agentName, workDir)
	c.log("Prompt length: %d chars", len(prompt))
	if len(prompt) < 2000 {
		c.log("Prompt content:\n%s", prompt)
	} else {
		c.log("Prompt content (first 2000 chars):\n%s...", prompt[:2000])
	}

	// Verify session exists
	c.log("Verifying session exists...")
	_, err := c.Session.Get(c.ctx, sessionID, opencode.SessionGetParams{})
	if err != nil {
		c.log("ERROR: session not found: %v", err)
		return nil, fmt.Errorf("session not found: %w", err)
	}
	c.log("Session verified")

	fmt.Fprintf(os.Stderr, "\n────────────────────────────────────────────────────────────────\n")
	fmt.Fprintf(os.Stderr, "Continuing session: %s\n", sessionID)
	fmt.Fprintf(os.Stderr, "────────────────────────────────────────────────────────────────\n\n")

	// Build prompt params
	params := opencode.SessionPromptParams{
		Directory: opencode.F(workDir),
		Parts: opencode.F([]opencode.SessionPromptParamsPartUnion{
			opencode.TextPartInputParam{
				Type: opencode.F(opencode.TextPartInputTypeText),
				Text: opencode.F(prompt),
			},
		}),
	}

	// Use agent unless NoAgent is set
	if opts == nil || !opts.NoAgent {
		params.Agent = opencode.F(agentName)
	}

	// Add tools if specified
	if opts != nil && opts.Tools != nil {
		params.Tools = opencode.F(opts.Tools)
	}

	// Add model override if specified
	if opts != nil && opts.Model != nil {
		params.Model = opencode.F(opencode.SessionPromptParamsModel{
			ProviderID: opencode.F(opts.Model.ProviderID),
			ModelID:    opencode.F(opts.Model.ModelID),
		})
	}

	// Add system prompt if specified
	if opts != nil && opts.System != "" {
		params.System = opencode.F(opts.System)
	}

	// Send prompt to existing session
	c.log("Sending prompt to session (this may take a while)...")
	startTime := time.Now()
	response, err := c.Session.Prompt(c.ctx, sessionID, params)
	elapsed := time.Since(startTime)

	if err != nil {
		c.log("ERROR: prompt failed after %v: %v", elapsed, err)
		return nil, fmt.Errorf("failed to send prompt: %w", err)
	}

	c.log("Prompt completed in %v", elapsed)
	c.log("Response parts count: %d", len(response.Parts))

	output := ExtractTextFromParts(response.Parts)
	c.log("Extracted text length: %d chars", len(output))
	if len(output) < 5000 {
		c.log("Response output:\n%s", output)
	} else {
		c.log("Response output (first 5000 chars):\n%s...", output[:5000])
	}

	return &AgentResult{
		Output:    output,
		SessionID: sessionID,
	}, nil
}

// PrintSessionFollowUp prints session follow-up instructions
func PrintSessionFollowUp(toolName, sessionID string) {
	fmt.Fprintf(os.Stderr, "\n────────────────────────────────────────────────────────────────\n")
	fmt.Fprintf(os.Stderr, "Session completed: %s\n", sessionID)
	fmt.Fprintf(os.Stderr, "To follow up: %s -s %s\n", toolName, sessionID)
	fmt.Fprintf(os.Stderr, "────────────────────────────────────────────────────────────────\n")
}

// ExtractTextFromParts extracts all text content from response parts
func ExtractTextFromParts(parts []opencode.Part) string {
	var texts []string

	for _, part := range parts {
		// Part has Type and Text fields directly
		if part.Type == opencode.PartTypeText && part.Text != "" {
			texts = append(texts, part.Text)
		}
	}

	return strings.Join(texts, "\n")
}

// ReadStdinOrArgs reads prompt from stdin (if piped) or from command line args
func ReadStdinOrArgs(args []string) (string, error) {
	// Check if stdin has data
	stat, _ := os.Stdin.Stat()
	if (stat.Mode() & os.ModeCharDevice) == 0 {
		// stdin has data (pipe or redirect)
		scanner := bufio.NewScanner(os.Stdin)
		var lines []string
		for scanner.Scan() {
			lines = append(lines, scanner.Text())
		}
		if err := scanner.Err(); err != nil {
			return "", fmt.Errorf("error reading stdin: %w", err)
		}
		prompt := strings.Join(lines, "\n")
		if prompt == "" {
			return "", fmt.Errorf("no prompt provided via stdin")
		}
		return prompt, nil
	}

	// No stdin data, use args
	if len(args) == 0 {
		return "", fmt.Errorf("no prompt provided")
	}
	return strings.Join(args, " "), nil
}

// Logger provides realtime streaming logging to file
type Logger struct {
	file      *os.File
	mu        sync.Mutex
	filePath  string
	toolName  string
	sessionID string
}

// NewLogger creates a new streaming logger for the given tool (new session)
func NewLogger(toolName string) (*Logger, error) {
	logDir := filepath.Join(os.Getenv("HOME"), ".cache", "scripts", toolName)
	if err := os.MkdirAll(logDir, 0755); err != nil {
		return nil, fmt.Errorf("failed to create log dir %s: %w", logDir, err)
	}

	timestamp := time.Now().Format("20060102T150405")
	logPath := filepath.Join(logDir, fmt.Sprintf("%s-%d.log", timestamp, os.Getpid()))

	file, err := os.OpenFile(logPath, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0644)
	if err != nil {
		return nil, fmt.Errorf("failed to open log file %s: %w", logPath, err)
	}

	l := &Logger{
		file:     file,
		filePath: logPath,
		toolName: toolName,
	}

	// Log initial header
	l.Log("=== %s started at %s ===", toolName, time.Now().Format(time.RFC3339))
	l.Log("PID: %d", os.Getpid())
	l.Log("Log file: %s", logPath)

	return l, nil
}

// NewLoggerForSession creates/appends to a session-specific log file
// Use this when continuing a session with -s SESSION_ID so all logs for that session are in one file
func NewLoggerForSession(toolName, sessionID string) (*Logger, error) {
	logDir := filepath.Join(os.Getenv("HOME"), ".cache", "scripts", toolName)
	if err := os.MkdirAll(logDir, 0755); err != nil {
		return nil, fmt.Errorf("failed to create log dir %s: %w", logDir, err)
	}

	// Use session ID in filename for easy lookup and appending
	logPath := filepath.Join(logDir, fmt.Sprintf("session-%s.log", sessionID))

	file, err := os.OpenFile(logPath, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0644)
	if err != nil {
		return nil, fmt.Errorf("failed to open log file %s: %w", logPath, err)
	}

	l := &Logger{
		file:      file,
		filePath:  logPath,
		toolName:  toolName,
		sessionID: sessionID,
	}

	// Log continuation header
	l.Log("")
	l.Log("=== %s CONTINUED at %s ===", toolName, time.Now().Format(time.RFC3339))
	l.Log("PID: %d", os.Getpid())
	l.Log("Session: %s", sessionID)

	return l, nil
}

// LinkSession creates a session-named symlink to this log file
// Call this after a new session is created so future continuations can find it
func (l *Logger) LinkSession(sessionID string) {
	l.mu.Lock()
	defer l.mu.Unlock()

	l.sessionID = sessionID
	logDir := filepath.Dir(l.filePath)
	linkPath := filepath.Join(logDir, fmt.Sprintf("session-%s.log", sessionID))

	// Remove existing link if present
	os.Remove(linkPath)

	// Create symlink to the actual log file
	if err := os.Symlink(l.filePath, linkPath); err != nil {
		// Fallback: just note in the log that the session file exists
		l.file.WriteString(fmt.Sprintf("[%s] Note: session link failed: %v\n",
			time.Now().Format("15:04:05.000"), err))
	}
}

// Log writes a timestamped message to the log file (realtime flush)
func (l *Logger) Log(format string, args ...interface{}) {
	l.mu.Lock()
	defer l.mu.Unlock()

	if l.file == nil {
		return
	}

	msg := fmt.Sprintf(format, args...)
	ts := time.Now().Format("15:04:05.000")
	line := fmt.Sprintf("[%s] %s\n", ts, msg)

	l.file.WriteString(line)
	l.file.Sync() // Force flush to disk immediately
}

// LogJSON writes a JSON object to the log (pretty-printed)
func (l *Logger) LogJSON(label string, v interface{}) {
	data, err := json.MarshalIndent(v, "", "  ")
	if err != nil {
		l.Log("%s: [JSON marshal error: %v]", label, err)
		return
	}
	l.Log("%s:\n%s", label, string(data))
}

// LogSeparator writes a visual separator
func (l *Logger) LogSeparator(label string) {
	l.Log("─────────────── %s ───────────────", label)
}

// Path returns the log file path
func (l *Logger) Path() string {
	return l.filePath
}

// Close closes the log file
func (l *Logger) Close() {
	l.mu.Lock()
	defer l.mu.Unlock()

	if l.file != nil {
		// Write final message directly (don't call l.Log which would deadlock)
		ts := time.Now().Format("15:04:05.000")
		l.file.WriteString(fmt.Sprintf("[%s] === %s ended at %s ===\n", ts, l.toolName, time.Now().Format(time.RFC3339)))
		l.file.Sync()
		l.file.Close()
		l.file = nil
	}
}

// Writer returns an io.Writer that writes to the log
func (l *Logger) Writer() io.Writer {
	return &logWriter{l: l}
}

type logWriter struct {
	l *Logger
}

func (w *logWriter) Write(p []byte) (n int, err error) {
	w.l.Log("%s", strings.TrimRight(string(p), "\n"))
	return len(p), nil
}

// SetupLogDir creates log directory and returns log file path
// DEPRECATED: Use NewLogger() instead for realtime streaming logs
func SetupLogDir(name string) (string, error) {
	logDir := filepath.Join(os.Getenv("HOME"), ".cache", "scripts", name)
	if err := os.MkdirAll(logDir, 0755); err != nil {
		return "", fmt.Errorf("failed to create log dir: %w", err)
	}

	timestamp := time.Now().Format("20060102T150405")
	logFile := filepath.Join(logDir, fmt.Sprintf("%s-%d.log", timestamp, os.Getpid()))
	return logFile, nil
}

// WriteLog writes content to log file
// DEPRECATED: Use Logger.Log() instead for realtime streaming logs
func WriteLog(logFile, content string) error {
	return os.WriteFile(logFile, []byte(content), 0644)
}

// WriteLogWithSession writes output and session ID to log file for follow-up
// DEPRECATED: Use Logger.Log() instead for realtime streaming logs
func WriteLogWithSession(logFile, output, sessionID string) error {
	content := fmt.Sprintf("SESSION_ID=%s\n\n%s", sessionID, output)
	return os.WriteFile(logFile, []byte(content), 0644)
}

// GetWorkDir returns current working directory
func GetWorkDir() string {
	wd, err := os.Getwd()
	if err != nil {
		return os.Getenv("HOME")
	}
	return wd
}
