package main

import (
	"context"
	"flag"
	"fmt"
	"os"
	"time"

	"tutero/oc-tools/shared"
)

const usage = `Usage: local-librarian [-s SESSION_ID] [-v]
   or: echo "prompt" | local-librarian [-s SESSION_ID]
   or: local-librarian [-s SESSION_ID] <<EOF
       prompt text here
       EOF

Options:
  -s, --session SESSION_ID    Continue an existing session
  -v                          Verbose mode (show logs location)
  -h, --help                  Show this help message

Note: Prompt must be provided via stdin (pipe or redirect)
      Always specify the directory to search in your prompt!

Examples:
  echo "Search ~/Coding/mathgaps-org to find how spans and logs are uploaded to Grafana" | local-librarian

  local-librarian <<EOF
  Search ~/Coding/myproject to find authentication logic.
  Look for middleware and JWT validation.
  EOF

  local-librarian -s ses_abc123 <<< "continue searching for related code"
`

func main() {
	// Isolate sessions from main opencode CLI
	shared.IsolateDataDir()

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
		logger, logErr = shared.NewLoggerForSession("local-librarian", sessionID)
	} else {
		logger, logErr = shared.NewLogger("local-librarian")
	}
	if logErr != nil {
		fmt.Fprintf(os.Stderr, "Warning: could not setup logging: %v\n", logErr)
	}
	if logger != nil {
		defer logger.Close()
	}

	if logger != nil {
		logger.Log("Arguments: session=%s, verbose=%v", sessionID, verbose)
	}

	// Check stdin - local-librarian requires piped input
	stat, _ := os.Stdin.Stat()
	if (stat.Mode() & os.ModeCharDevice) != 0 {
		if logger != nil {
			logger.Log("ERROR: no stdin provided")
		}
		fmt.Fprintf(os.Stderr, "Error: Prompt must be provided via stdin (pipe or redirect)\n")
		fmt.Fprint(os.Stderr, usage)
		os.Exit(1)
	}

	// Read prompt from stdin
	prompt, err := shared.ReadStdinOrArgs(nil)
	if err != nil {
		if logger != nil {
			logger.Log("ERROR: %v", err)
		}
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		fmt.Fprint(os.Stderr, usage)
		os.Exit(1)
	}

	// Capture invoke directory before changing to $HOME
	invokeDir := shared.GetWorkDir()

	if logger != nil {
		logger.LogSeparator("INPUT")
		logger.Log("Invoke directory: %s", invokeDir)
		logger.Log("Raw prompt:\n%s", prompt)
	}

	// Prepend invocation directory context (fallback if no dir specified)
	contextPrefix := fmt.Sprintf("Invoked Dir (CWD): %s\n(use as fallback if no dir specified to search)\n\n", invokeDir)
	prompt = contextPrefix + prompt

	if logger != nil {
		logger.Log("With context prefix, total length: %d chars", len(prompt))
	}

	// Run from $HOME for read-only access to all repos
	workDir := os.Getenv("HOME")

	if logger != nil {
		logger.LogSeparator("SDK SETUP")
		logger.Log("Work directory: %s", workDir)
	}

	// Create context with timeout
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Minute)
	defer cancel()

	client := shared.NewClientWithLogger(ctx, logger)
	defer client.Close()

	var result *shared.AgentResult

	if logger != nil {
		logger.LogSeparator("AGENT CALL")
	}

	if sessionID != "" {
		if logger != nil {
			logger.Log("Continuing existing session: %s", sessionID)
		}
		result, err = client.ContinueSession(sessionID, "local-librarian", prompt, workDir)
	} else {
		if logger != nil {
			logger.Log("Starting new session")
		}
		result, err = client.RunAgent("local-librarian", prompt, workDir)
	}

	if err != nil {
		if logger != nil {
			logger.Log("ERROR: agent call failed: %v", err)
		}
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
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
	shared.PrintSessionFollowUp("local-librarian", result.SessionID)
}
