package main

import (
	"context"
	"flag"
	"fmt"
	"os"
	"time"

	"tutero/oc-tools/shared"
)

const usage = `Usage: web-search [-s SESSION_ID] [-v] "prompt"
   or: echo "prompt" | web-search [-s SESSION_ID]

Options:
  -s, --session SESSION_ID    Continue an existing session
  -v                          Verbose mode (show logs location)
  -h, --help                  Show this help message

Examples:
  web-search "latest news on AI"
  echo "what is the weather in NYC" | web-search
  web-search -s ses_abc123 "find more details on that topic"
`

const maxRetries = 2

// Fallback model when no free opencode models available
var fallbackModel = &shared.ModelConfig{
	ProviderID: "anthropic",
	ModelID:    "claude-haiku-4-5",
}

func main() {
	// Isolate sessions from main opencode CLI
	shared.IsolateDataDir()

	// Prevent recursive invocation - opencode's web-search agent may call this script
	if os.Getenv("_WEB_SEARCH_RUNNING") == "1" {
		fmt.Fprintln(os.Stderr, "Error: web-search cannot be called recursively")
		os.Exit(1)
	}
	os.Setenv("_WEB_SEARCH_RUNNING", "1")

	var sessionID string
	var verbose bool
	var showHelp bool

	flag.StringVar(&sessionID, "s", "", "Continue an existing session")
	flag.StringVar(&sessionID, "session", "", "Continue an existing session")
	flag.BoolVar(&verbose, "v", false, "Verbose mode")
	flag.BoolVar(&showHelp, "help", false, "Show help")
	flag.BoolVar(&showHelp, "h", false, "Show help")
	flag.Parse()

	if showHelp {
		fmt.Fprint(os.Stderr, usage)
		os.Exit(0)
	}

	// Setup logging FIRST (before any other operations)
	// Use session-specific log file if continuing, otherwise create new timestamped log
	var logger *shared.Logger
	var logErr error
	if sessionID != "" {
		logger, logErr = shared.NewLoggerForSession("web-search", sessionID)
	} else {
		logger, logErr = shared.NewLogger("web-search")
	}
	if logErr != nil {
		fmt.Fprintf(os.Stderr, "Warning: could not setup logging: %v\n", logErr)
	}
	if logger != nil {
		defer logger.Close()
	}

	if logger != nil {
		logger.Log("Arguments: session=%s, verbose=%v, args=%v", sessionID, verbose, flag.Args())
	}

	// Read prompt from args first, fall back to stdin
	prompt, err := shared.ReadStdinOrArgs(flag.Args())
	if err != nil {
		if logger != nil {
			logger.Log("ERROR: %v", err)
		}
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		fmt.Fprint(os.Stderr, usage)
		os.Exit(1)
	}

	if logger != nil {
		logger.LogSeparator("INPUT")
		logger.Log("Prompt:\n%s", prompt)
	}

	// Use /tmp to prevent loading any project AGENTS.md files
	// Web-search only needs its own agent file at ~/.config/opencode/agent/web-search.md
	workDir := "/tmp"

	if logger != nil {
		logger.LogSeparator("SDK SETUP")
		logger.Log("Work directory: %s", workDir)
	}

	// Create context with timeout
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Minute)
	defer cancel()

	client := shared.NewClientWithLogger(ctx, logger)
	defer client.Close()

	// Find best free model from opencode provider (required for websearch tool)
	if logger != nil {
		logger.Log("Finding best free model...")
	}
	model, err := client.FindBestFreeModel()
	if err != nil {
		if logger != nil {
			logger.Log("Warning: could not query models: %v", err)
		}
		fmt.Fprintf(os.Stderr, "Warning: could not query models: %v\n", err)
	}

	// Build options: use web-search agent (keeps instructions from ~/.opencode/agent/web-search.md)
	// but override model to opencode provider for websearch tool compatibility
	opts := &shared.AgentOptions{
		Tools: map[string]bool{
			"websearch": true,
		},
	}

	if model != nil {
		// Use free opencode model (required for websearch tool to work)
		opts.Model = &shared.ModelConfig{
			ProviderID: model.ProviderID,
			ModelID:    model.ModelID,
		}
		if logger != nil {
			logger.Log("Using free model: %s/%s", model.ProviderID, model.ModelID)
		}
		fmt.Fprintf(os.Stderr, "[web-search] Using free model: %s/%s\n", model.ProviderID, model.ModelID)
	} else {
		// Fallback to haiku - websearch tool won't work but basic search might
		opts.Model = fallbackModel
		if logger != nil {
			logger.Log("No free opencode models, falling back to %s/%s", fallbackModel.ProviderID, fallbackModel.ModelID)
		}
		fmt.Fprintf(os.Stderr, "[web-search] No free opencode models, falling back to %s/%s (websearch tool disabled)\n",
			fallbackModel.ProviderID, fallbackModel.ModelID)
		// Disable websearch tool since it won't work with non-opencode provider
		opts.Tools["websearch"] = false
	}

	var result *shared.AgentResult
	var lastErr error

	if logger != nil {
		logger.LogSeparator("AGENT CALL")
	}

	// Retry loop for transient failures
	for attempt := 0; attempt < maxRetries; attempt++ {
		if logger != nil {
			logger.Log("Attempt %d/%d", attempt+1, maxRetries)
		}

		if sessionID != "" {
			if logger != nil {
				logger.Log("Continuing existing session: %s", sessionID)
			}
			result, lastErr = client.ContinueSessionWithOptions(sessionID, "web-search", prompt, workDir, opts)
		} else {
			if logger != nil {
				logger.Log("Starting new session")
			}
			result, lastErr = client.RunAgentWithOptions("web-search", prompt, workDir, opts)
		}

		if lastErr == nil {
			break
		}

		if logger != nil {
			logger.Log("Attempt %d failed: %v", attempt+1, lastErr)
		}
		if attempt < maxRetries-1 {
			fmt.Fprintf(os.Stderr, "[retry %d/%d after error: %v]\n", attempt+1, maxRetries, lastErr)
			time.Sleep(500 * time.Millisecond)
		}
	}

	if lastErr != nil {
		if logger != nil {
			logger.Log("ERROR: all retries failed: %v", lastErr)
		}
		fmt.Fprintf(os.Stderr, "Error: %v\n", lastErr)
		os.Exit(1)
	}

	// Link session log for new sessions so future continuations find it
	if logger != nil && sessionID == "" {
		logger.LinkSession(result.SessionID)
	}

	if logger != nil {
		logger.LogSeparator("RESULT")
		logger.Log("Session ID: %s", result.SessionID)
		logger.Log("Output length: %d chars", len(result.Output))
	}

	if verbose {
		fmt.Fprintf(os.Stderr, "[debug] Logs saved to: %s\n", logger.Path())
	}

	// Print output
	fmt.Println(result.Output)

	// Print session follow-up instructions
	shared.PrintSessionFollowUp("web-search", result.SessionID)
}
