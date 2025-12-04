package shared

import (
	"bufio"
	"context"
	"fmt"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
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
}

// NewClient creates opencode client, auto-starting server if needed (like TS SDK createOpencode)
func NewClient(ctx context.Context) *Client {
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
	}

	// Check if server is already running
	if !c.isServerRunning() {
		// Start server subprocess (mimics TS SDK createOpencodeServer pattern)
		if url, err := c.startServer(); err != nil {
			fmt.Fprintf(os.Stderr, "[opencode] Warning: could not start server: %v\n", err)
			fmt.Fprintf(os.Stderr, "[opencode] Ensure 'opencode' is installed and in PATH\n")
		} else {
			c.baseURL = url
		}
	}

	c.Client = opencode.NewClient(
		option.WithBaseURL(c.baseURL),
	)

	return c
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

			// Check if supports tool calls (needed for websearch)
			if !model.ToolCall {
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
	// Create session
	session, err := c.Session.New(c.ctx, opencode.SessionNewParams{
		Directory: opencode.F(workDir),
		Title:     opencode.F(fmt.Sprintf("%s-%d", agentName, time.Now().Unix())),
	})
	if err != nil {
		return nil, fmt.Errorf("failed to create session: %w", err)
	}

	sessionID := session.ID

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
	response, err := c.Session.Prompt(c.ctx, sessionID, params)

	if err != nil {
		return nil, fmt.Errorf("failed to send prompt: %w", err)
	}

	return &AgentResult{
		Output:    ExtractTextFromParts(response.Parts),
		SessionID: sessionID,
	}, nil
}

// ContinueSession sends a follow-up prompt to an existing session
func (c *Client) ContinueSession(sessionID, agentName, prompt, workDir string) (*AgentResult, error) {
	return c.ContinueSessionWithOptions(sessionID, agentName, prompt, workDir, nil)
}

// ContinueSessionWithOptions sends a follow-up prompt with optional settings
func (c *Client) ContinueSessionWithOptions(sessionID, agentName, prompt, workDir string, opts *AgentOptions) (*AgentResult, error) {
	// Verify session exists
	_, err := c.Session.Get(c.ctx, sessionID, opencode.SessionGetParams{})
	if err != nil {
		return nil, fmt.Errorf("session not found: %w", err)
	}

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
	response, err := c.Session.Prompt(c.ctx, sessionID, params)

	if err != nil {
		return nil, fmt.Errorf("failed to send prompt: %w", err)
	}

	return &AgentResult{
		Output:    ExtractTextFromParts(response.Parts),
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

// SetupLogDir creates log directory and returns log file path
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
func WriteLog(logFile, content string) error {
	return os.WriteFile(logFile, []byte(content), 0644)
}

// WriteLogWithSession writes output and session ID to log file for follow-up
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
