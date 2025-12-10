package main

import (
	"context"
	"flag"
	"fmt"
	"os"
	"time"

	"github.com/sst/opencode-sdk-go"
	"github.com/sst/opencode-sdk-go/option"
	"tutero/oc-tools/shared"
)

const usage = `Usage: branch-namer [-v] "PR title or description"
   or: echo "PR title" | branch-namer

Generates a kebab-case branch/folder name from a PR title.
Sessions are automatically deleted after use (no history pollution).

Options:
  -v              Verbose mode (show logs location)
  -h, --help      Show this help message

Output: JSON with branchName field, e.g. {"branchName": "fix-auth-bug"}
`

func main() {
	var verbose bool
	var showHelp bool

	flag.BoolVar(&verbose, "v", false, "Verbose mode")
	flag.BoolVar(&showHelp, "help", false, "Show help")
	flag.BoolVar(&showHelp, "h", false, "Show help")
	flag.Parse()

	if showHelp {
		fmt.Fprint(os.Stderr, usage)
		os.Exit(0)
	}

	// Setup logging FIRST (before any other operations)
	logger, err := shared.NewLogger("branch-namer")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Warning: could not setup logging: %v\n", err)
	}
	if logger != nil {
		defer logger.Close()
	}

	if logger != nil {
		logger.Log("Arguments: verbose=%v, args=%v", verbose, flag.Args())
	}

	// Read prompt from args or stdin
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

	// Use /tmp as workdir to isolate from real projects
	workDir := "/tmp"

	if logger != nil {
		logger.LogSeparator("SDK SETUP")
		logger.Log("Work directory: %s", workDir)
	}

	// Create context with short timeout (branch naming is quick)
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
	defer cancel()

	// Create client directly (not using shared.NewClient to avoid extra output)
	baseURL := os.Getenv("OPENCODE_URL")
	if baseURL == "" {
		baseURL = fmt.Sprintf("http://%s:%d", shared.DefaultHostname, shared.DefaultPort)
	}

	if logger != nil {
		logger.Log("SDK base URL: %s", baseURL)
	}

	client := opencode.NewClient(option.WithBaseURL(baseURL))

	// Create session
	if logger != nil {
		logger.Log("Creating session...")
	}
	session, err := client.Session.New(ctx, opencode.SessionNewParams{
		Directory: opencode.F(workDir),
		Title:     opencode.F("branch-namer-tmp"),
	})
	if err != nil {
		if logger != nil {
			logger.Log("ERROR: creating session: %v", err)
		}
		fmt.Fprintf(os.Stderr, "Error creating session: %v\n", err)
		os.Exit(1)
	}

	sessionID := session.ID
	if logger != nil {
		logger.Log("Session created: %s", sessionID)
	}

	// Ensure session is deleted when we're done (cleanup)
	defer func() {
		if logger != nil {
			logger.Log("Cleaning up session: %s", sessionID)
		}
		deleteCtx, deleteCancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer deleteCancel()
		_, delErr := client.Session.Delete(deleteCtx, sessionID, opencode.SessionDeleteParams{
			Directory: opencode.F(workDir),
		})
		if logger != nil {
			if delErr != nil {
				logger.Log("Session cleanup error: %v", delErr)
			} else {
				logger.Log("Session cleaned up successfully")
			}
		}
	}()

	// Send prompt to branch-namer agent
	if logger != nil {
		logger.LogSeparator("AGENT CALL")
		logger.Log("Sending prompt to branch-namer agent...")
	}
	startTime := time.Now()
	response, err := client.Session.Prompt(ctx, sessionID, opencode.SessionPromptParams{
		Agent:     opencode.F("branch-namer"),
		Directory: opencode.F(workDir),
		Parts: opencode.F([]opencode.SessionPromptParamsPartUnion{
			opencode.TextPartInputParam{
				Type: opencode.F(opencode.TextPartInputTypeText),
				Text: opencode.F(prompt),
			},
		}),
	})
	elapsed := time.Since(startTime)

	if err != nil {
		if logger != nil {
			logger.Log("ERROR: prompt failed after %v: %v", elapsed, err)
		}
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}

	if logger != nil {
		logger.Log("Prompt completed in %v", elapsed)
		logger.Log("Response parts: %d", len(response.Parts))
	}

	// Extract and print output (just the text, no session info)
	output := shared.ExtractTextFromParts(response.Parts)

	if logger != nil {
		logger.LogSeparator("RESULT")
		logger.Log("Output:\n%s", output)
	}

	if verbose {
		fmt.Fprintf(os.Stderr, "[debug] Logs saved to: %s\n", logger.Path())
	}

	fmt.Println(output)
}
