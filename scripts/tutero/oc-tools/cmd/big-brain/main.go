package main

import (
	"context"
	"flag"
	"fmt"
	"os"
	"time"

	"tutero/oc-tools/shared"
)

const usage = `Usage: big-brain [-s SESSION_ID] "prompt"
   or: echo "prompt" | big-brain [-s SESSION_ID]
   or: big-brain [-s SESSION_ID] <<EOF
       prompt text here
       EOF

Options:
  -s, --session SESSION_ID    Continue an existing session
  -v                          Verbose mode (show logs location)
  -h, --help                  Show this help message

Examples:
  big-brain "How should we refactor the auth system?"
  echo "What's the best approach for real-time notifications?" | big-brain
  big-brain -s ses_abc123 "continue with the implementation details"
`

// Oracle instruction prepended to prompts (read-only advisory role)
const oracleInstruction = `You are a read-only advisory oracle consulted for complex analysis, planning, and reviews.
Do not perform implementation work yourself - focus strictly on researching, analyzing, and providing expert guidance.
Review the situation thoroughly and respond with actionable advice that adheres to the query's requirements.

USER QUERY:
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
		logger, logErr = shared.NewLoggerForSession("big-brain", sessionID)
	} else {
		logger, logErr = shared.NewLogger("big-brain")
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

	// Read prompt from stdin or args
	prompt, err := shared.ReadStdinOrArgs(flag.Args())
	if err != nil {
		if logger != nil {
			logger.Log("ERROR: %v", err)
		}
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		fmt.Fprint(os.Stderr, usage)
		fmt.Fprintln(os.Stderr, "\nUse --help for more information")
		os.Exit(1)
	}

	if logger != nil {
		logger.LogSeparator("INPUT")
		logger.Log("Raw prompt:\n%s", prompt)
	}

	// Prepend oracle instruction for read-only advisory behavior
	prompt = oracleInstruction + prompt

	if logger != nil {
		logger.Log("With oracle instruction, total length: %d chars", len(prompt))
	}

	// Run from current directory
	workDir := shared.GetWorkDir()

	if logger != nil {
		logger.LogSeparator("SDK SETUP")
		logger.Log("Work directory: %s", workDir)
	}

	// Create context with timeout
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Minute)
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
		result, err = client.ContinueSession(sessionID, "big-brain", prompt, workDir)
	} else {
		if logger != nil {
			logger.Log("Starting new session")
		}
		result, err = client.RunAgent("big-brain", prompt, workDir)
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
	shared.PrintSessionFollowUp("big-brain", result.SessionID)
}
