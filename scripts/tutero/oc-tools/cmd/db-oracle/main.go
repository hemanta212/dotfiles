package main

import (
	"context"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"

	"tutero/oc-tools/shared"
)

const usage = `Usage: db-oracle -db <resources|learning|teaching> [-s SESSION_ID] [-v] [--dirs <dir1> <dir2> ...]

Arguments:
  -db <name>        Database to query (required): resources, learning, or teaching
  -s SESSION_ID     Continue an existing session
  -v                Verbose mode (show logs location)
  --dirs <dirs...>  Additional directories to reference in the prompt
  --help, -h        Show this help message

Note: Prompt must be provided via stdin (pipe or redirect)

Examples:
  echo "List all courses" | db-oracle -db learning
  cat query.txt | db-oracle -db teaching
  cat prompt.txt | db-oracle -db resources --dirs backend/app frontend/src
  db-oracle -db resources -s ses_abc123 <<< "continue with the query"
`

func main() {
	// Isolate sessions from main opencode CLI
	shared.IsolateDataDir()

	var db string
	var sessionID string
	var verbose bool
	var showHelp bool

	flag.StringVar(&db, "db", "", "Database to query: resources, learning, or teaching")
	flag.StringVar(&sessionID, "s", "", "Continue an existing session")
	flag.StringVar(&sessionID, "session", "", "Continue an existing session")
	flag.BoolVar(&verbose, "v", false, "Verbose mode")
	flag.BoolVar(&showHelp, "help", false, "Show help")
	flag.BoolVar(&showHelp, "h", false, "Show help")

	// Custom parsing for --dirs which takes multiple values
	var dirs []string
	args := os.Args[1:]
	var filteredArgs []string

	for i := 0; i < len(args); i++ {
		if args[i] == "--dirs" {
			i++
			for i < len(args) && !strings.HasPrefix(args[i], "-") {
				dirs = append(dirs, args[i])
				i++
			}
			i-- // Back up one since the loop will increment
		} else {
			filteredArgs = append(filteredArgs, args[i])
		}
	}

	// Parse remaining flags
	flag.CommandLine.Parse(filteredArgs)

	if showHelp {
		fmt.Fprint(os.Stderr, usage)
		os.Exit(0)
	}

	// Setup logging FIRST (before any other operations)
	// Use session-specific log file if continuing, otherwise create new timestamped log
	var logger *shared.Logger
	var logErr error
	if sessionID != "" {
		logger, logErr = shared.NewLoggerForSession("db-oracle", sessionID)
	} else {
		logger, logErr = shared.NewLogger("db-oracle")
	}
	if logErr != nil {
		fmt.Fprintf(os.Stderr, "Warning: could not setup logging: %v\n", logErr)
	}
	if logger != nil {
		defer logger.Close()
	}

	if logger != nil {
		logger.Log("Arguments: db=%s, session=%s, verbose=%v, dirs=%v", db, sessionID, verbose, dirs)
	}

	if db == "" {
		repoName := getRepoName()
		errMsg := fmt.Sprintf("Error: -db argument is required (repo: %s)", repoName)
		if logger != nil {
			logger.Log("ERROR: %s", errMsg)
		}
		fmt.Fprintf(os.Stderr, "Error: -db argument is required\n")
		fmt.Fprintf(os.Stderr, "Usage: echo \"prompt\" | db-oracle -db <resources|learning|teaching> [-s SESSION_ID] [-v] [--dirs <dir1> <dir2> ...]\n")
		fmt.Fprintf(os.Stderr, "Hint: You're currently in repo: '%s'\n", repoName)
		os.Exit(1)
	}

	validDBs := map[string]bool{"resources": true, "learning": true, "teaching": true}
	if !validDBs[db] {
		if logger != nil {
			logger.Log("ERROR: invalid db: %s", db)
		}
		fmt.Fprintf(os.Stderr, "Error: -db must be one of: resources, learning, teaching\n")
		os.Exit(1)
	}

	// Check stdin
	stat, _ := os.Stdin.Stat()
	if (stat.Mode() & os.ModeCharDevice) != 0 {
		if logger != nil {
			logger.Log("ERROR: no stdin provided")
		}
		fmt.Fprintf(os.Stderr, "Error: Prompt must be provided via stdin (pipe or redirect)\n")
		fmt.Fprintf(os.Stderr, "Usage: echo \"prompt\" | db-oracle -db <resources|learning|teaching> [-s SESSION_ID] [-v] [--dirs <dir1> <dir2> ...]\n")
		os.Exit(1)
	}

	// Read prompt from stdin
	prompt, err := shared.ReadStdinOrArgs(nil)
	if err != nil {
		if logger != nil {
			logger.Log("ERROR reading prompt: %v", err)
		}
		fmt.Fprintf(os.Stderr, "Error reading prompt: %v\n", err)
		os.Exit(1)
	}

	if logger != nil {
		logger.LogSeparator("INPUT")
		logger.Log("Database: %s", db)
		logger.Log("Directories: %v", dirs)
		logger.Log("Raw prompt:\n%s", prompt)
	}

	// Build final prompt with dirs context
	var finalPrompt strings.Builder
	if len(dirs) > 0 {
		finalPrompt.WriteString("Referenced Project/Repositories directories:\n")
		for _, dir := range dirs {
			finalPrompt.WriteString(fmt.Sprintf("- %s\n", dir))
		}
		finalPrompt.WriteString("\n")
	}
	finalPrompt.WriteString(prompt)

	if logger != nil {
		logger.Log("Final prompt:\n%s", finalPrompt.String())
	}

	// Run from metarepo
	workDir := filepath.Join(os.Getenv("HOME"), "Coding", "metarepo")

	if logger != nil {
		logger.LogSeparator("SDK SETUP")
		logger.Log("Work directory: %s", workDir)
	}

	// Create context with timeout (db-oracle can take very long due to opus model)
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Minute)
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
		result, err = client.ContinueSession(sessionID, "db-oracle", finalPrompt.String(), workDir)
	} else {
		if logger != nil {
			logger.Log("Starting new session")
		}
		result, err = client.RunAgent("db-oracle", finalPrompt.String(), workDir)
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
	shared.PrintSessionFollowUp("db-oracle", result.SessionID)
}

func getRepoName() string {
	wd, err := os.Getwd()
	if err != nil {
		return "unknown"
	}
	return filepath.Base(wd)
}
