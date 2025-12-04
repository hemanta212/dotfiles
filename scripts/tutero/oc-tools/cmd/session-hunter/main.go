package main

import (
	"context"
	"flag"
	"fmt"
	"os"
	"time"

	"tutero/oc-tools/shared"
)

const usage = `Usage: session-hunter [-s SESSION_ID] "prompt"
   or: echo "prompt" | session-hunter [-s SESSION_ID]
   or: session-hunter [-s SESSION_ID] <<EOF
       prompt text here
       EOF

Options:
  -s, --session SESSION_ID    Continue an existing session
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

	// Read prompt from stdin or args
	prompt, err := shared.ReadStdinOrArgs(flag.Args())
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		fmt.Fprint(os.Stderr, usage)
		fmt.Fprintln(os.Stderr, "\nUse --help for more information")
		os.Exit(1)
	}

	// Setup logging
	logFile, err := shared.SetupLogDir("session-hunter")
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

	var result *shared.AgentResult

	if sessionID != "" {
		// Continue existing session
		result, err = client.ContinueSession(sessionID, "session-hunter", prompt, workDir)
	} else {
		// Start new session
		result, err = client.RunAgent("session-hunter", prompt, workDir)
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
	}

	// Print output
	fmt.Println(result.Output)

	// Print session follow-up instructions
	shared.PrintSessionFollowUp("session-hunter", result.SessionID)
}
