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

	// Check stdin - local-librarian requires piped input
	stat, _ := os.Stdin.Stat()
	if (stat.Mode() & os.ModeCharDevice) != 0 {
		fmt.Fprintf(os.Stderr, "Error: Prompt must be provided via stdin (pipe or redirect)\n")
		fmt.Fprint(os.Stderr, usage)
		os.Exit(1)
	}

	// Read prompt from stdin
	prompt, err := shared.ReadStdinOrArgs(nil)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		fmt.Fprint(os.Stderr, usage)
		os.Exit(1)
	}

	// Capture invoke directory before changing to $HOME
	invokeDir := shared.GetWorkDir()

	// Prepend invocation directory context (fallback if no dir specified)
	contextPrefix := fmt.Sprintf("Invoked Dir (CWD): %s\n(use as fallback if no dir specified to search)\n\n", invokeDir)
	prompt = contextPrefix + prompt

	// Setup logging
	logFile, err := shared.SetupLogDir("local-librarian")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Warning: could not setup logging: %v\n", err)
	}

	// Run from $HOME for read-only access to all repos
	workDir := os.Getenv("HOME")

	// Create context with timeout
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Minute)
	defer cancel()

	client := shared.NewClient(ctx)
	defer client.Close()

	var result *shared.AgentResult

	if sessionID != "" {
		// Continue existing session
		result, err = client.ContinueSession(sessionID, "local-librarian", prompt, workDir)
	} else {
		// Start new session
		result, err = client.RunAgent("local-librarian", prompt, workDir)
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
	shared.PrintSessionFollowUp("local-librarian", result.SessionID)
}
