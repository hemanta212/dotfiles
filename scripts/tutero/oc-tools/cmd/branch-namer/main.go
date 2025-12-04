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

const usage = `Usage: branch-namer "PR title or description"
   or: echo "PR title" | branch-namer

Generates a kebab-case branch/folder name from a PR title.
Sessions are automatically deleted after use (no history pollution).

Options:
  -h, --help    Show this help message

Output: JSON with branchName field, e.g. {"branchName": "fix-auth-bug"}
`

func main() {
	var showHelp bool

	flag.BoolVar(&showHelp, "help", false, "Show help")
	flag.BoolVar(&showHelp, "h", false, "Show help")
	flag.Parse()

	if showHelp {
		fmt.Fprint(os.Stderr, usage)
		os.Exit(0)
	}

	// Read prompt from args or stdin
	prompt, err := shared.ReadStdinOrArgs(flag.Args())
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		fmt.Fprint(os.Stderr, usage)
		os.Exit(1)
	}

	// Use /tmp as workdir to isolate from real projects
	workDir := "/tmp"

	// Create context with short timeout (branch naming is quick)
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
	defer cancel()

	// Create client directly (not using shared.NewClient to avoid extra output)
	baseURL := os.Getenv("OPENCODE_URL")
	if baseURL == "" {
		baseURL = fmt.Sprintf("http://%s:%d", shared.DefaultHostname, shared.DefaultPort)
	}

	client := opencode.NewClient(option.WithBaseURL(baseURL))

	// Create session
	session, err := client.Session.New(ctx, opencode.SessionNewParams{
		Directory: opencode.F(workDir),
		Title:     opencode.F("branch-namer-tmp"),
	})
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error creating session: %v\n", err)
		os.Exit(1)
	}

	sessionID := session.ID

	// Ensure session is deleted when we're done (cleanup)
	defer func() {
		deleteCtx, deleteCancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer deleteCancel()
		_, _ = client.Session.Delete(deleteCtx, sessionID, opencode.SessionDeleteParams{
			Directory: opencode.F(workDir),
		})
	}()

	// Send prompt to branch-namer agent
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

	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}

	// Extract and print output (just the text, no session info)
	output := shared.ExtractTextFromParts(response.Parts)
	fmt.Println(output)
}
