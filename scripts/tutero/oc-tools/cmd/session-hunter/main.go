package main

import (
	"context"
	"flag"
	"fmt"
	"os"
	"time"

	"tutero/oc-tools/shared"
)

const usage = `Usage: session-hunter [-s SESSION_ID] [-v] "prompt"
   or: echo "prompt" | session-hunter [-s SESSION_ID]
   or: session-hunter [-s SESSION_ID] <<EOF
       prompt text here
       EOF

Options:
  -s, --session SESSION_ID    Continue an existing session
  -v                          Verbose mode (show logs location)
  -h, --help                  Show this help message

Examples:
  session-hunter "Find session where UpdateLessonPlanForClass was replaced"
  session-hunter "Which session modified worksheet_app_bar.dart?"
  echo "Find all sessions that touched frontend/app/schools-app" | session-hunter
  session-hunter -s ses_abc123 "search for more sessions with similar changes"
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
		logger, logErr = shared.NewLoggerForSession("session-hunter", sessionID)
	} else {
		logger, logErr = shared.NewLogger("session-hunter")
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
		logger.Log("Prompt:\n%s", prompt)
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
		result, err = client.ContinueSession(sessionID, "session-hunter", prompt, workDir)
	} else {
		if logger != nil {
			logger.Log("Starting new session")
		}
		result, err = client.RunAgent("session-hunter", prompt, workDir)
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
	shared.PrintSessionFollowUp("session-hunter", result.SessionID)
}
