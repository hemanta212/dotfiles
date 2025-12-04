package main

import (
	"context"
	"flag"
	"fmt"
	"os"
	"time"

	"tutero/oc-tools/shared"
)

const usage = `Usage: web-search [-s SESSION_ID] "prompt"
   or: echo "prompt" | web-search [-s SESSION_ID]

Options:
  -s, --session SESSION_ID    Continue an existing session
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
	var showHelp bool

	flag.StringVar(&sessionID, "s", "", "Continue an existing session")
	flag.StringVar(&sessionID, "session", "", "Continue an existing session")
	flag.BoolVar(&showHelp, "help", false, "Show help")
	flag.BoolVar(&showHelp, "h", false, "Show help")
	flag.Parse()

	if showHelp {
		fmt.Fprint(os.Stderr, usage)
		os.Exit(0)
	}

	// Read prompt from args first, fall back to stdin
	prompt, err := shared.ReadStdinOrArgs(flag.Args())
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		fmt.Fprint(os.Stderr, usage)
		os.Exit(1)
	}

	// Setup logging
	logFile, err := shared.SetupLogDir("web-search")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Warning: could not setup logging: %v\n", err)
	}

	// Run from current directory
	workDir := shared.GetWorkDir()

	// Create context with timeout
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Minute)
	defer cancel()

	client := shared.NewClient(ctx)
	defer client.Close()

	// Find best free model from opencode provider (required for websearch tool)
	model, err := client.FindBestFreeModel()
	if err != nil {
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
		fmt.Fprintf(os.Stderr, "[web-search] Using free model: %s/%s\n", model.ProviderID, model.ModelID)
	} else {
		// Fallback to haiku - websearch tool won't work but basic search might
		opts.Model = fallbackModel
		fmt.Fprintf(os.Stderr, "[web-search] No free opencode models, falling back to %s/%s (websearch tool disabled)\n",
			fallbackModel.ProviderID, fallbackModel.ModelID)
		// Disable websearch tool since it won't work with non-opencode provider
		opts.Tools["websearch"] = false
	}

	var result *shared.AgentResult
	var lastErr error

	// Retry loop for transient failures
	for attempt := 0; attempt < maxRetries; attempt++ {
		if sessionID != "" {
			// Continue existing session
			result, lastErr = client.ContinueSessionWithOptions(sessionID, "web-search", prompt, workDir, opts)
		} else {
			// Start new session with web-search agent (instructions from config)
			result, lastErr = client.RunAgentWithOptions("web-search", prompt, workDir, opts)
		}

		if lastErr == nil {
			break
		}

		if attempt < maxRetries-1 {
			fmt.Fprintf(os.Stderr, "[retry %d/%d after error: %v]\n", attempt+1, maxRetries, lastErr)
			time.Sleep(500 * time.Millisecond)
		}
	}

	if lastErr != nil {
		errMsg := fmt.Sprintf("Error: %v\n", lastErr)
		if logFile != "" {
			shared.WriteLog(logFile, errMsg)
		}
		fmt.Fprint(os.Stderr, errMsg)
		os.Exit(1)
	}

	// Log output with session ID for follow-up
	if logFile != "" {
		shared.WriteLogWithSession(logFile, result.Output, result.SessionID)
	}

	// Print output
	fmt.Println(result.Output)

	// Print session follow-up instructions
	shared.PrintSessionFollowUp("web-search", result.SessionID)
}
