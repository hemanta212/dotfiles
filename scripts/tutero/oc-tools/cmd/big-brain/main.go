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

	// Prepend oracle instruction for read-only advisory behavior
	prompt = oracleInstruction + prompt

	// Setup logging
	logFile, err := shared.SetupLogDir("big-brain")
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
		result, err = client.ContinueSession(sessionID, "big-brain", prompt, workDir)
	} else {
		// Start new session
		result, err = client.RunAgent("big-brain", prompt, workDir)
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
	shared.PrintSessionFollowUp("big-brain", result.SessionID)
}
