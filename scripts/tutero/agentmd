#!/bin/bash

# agentmd - Update AGENTS.md skills section and output complete context
# Updates ONLY the last code block in ~/.config/AGENTS.md with fresh skill info
# Outputs the full content with date, pwd, and project-specific AGENTS.md appended

set -e

AGENTS_FILE="$HOME/.config/AGENTS.md"
SKILLS_DIR="$HOME/.config/opencode/skills"
INFO_SCRIPT=".info"

# Get the directory where the script was invoked from
INVOKED_FROM="$PWD"
PROJECT_AGENTS="$INVOKED_FROM/AGENTS.md"

# Check if AGENTS.md exists
if [ ! -f "$AGENTS_FILE" ]; then
  echo "Error: $AGENTS_FILE not found" >&2
  exit 1
fi

# Check if skills directory exists
if [ ! -d "$SKILLS_DIR" ]; then
  echo "Error: $SKILLS_DIR not found" >&2
  exit 1
fi

# Check if .info script exists
if [ ! -f "$SKILLS_DIR/$INFO_SCRIPT" ]; then
  echo "Error: $SKILLS_DIR/$INFO_SCRIPT not found" >&2
  exit 1
fi

# Execute .info script from skills directory
cd "$SKILLS_DIR"
SKILLS_OUTPUT=$(bash "$INFO_SCRIPT")

# Get current date
CURRENT_DATE=$(date +"%Y-%m-%d")

# Find all ``` markers and get line numbers
CODE_BLOCKS=$(grep -n '^```' "$AGENTS_FILE" | cut -d: -f1)
CODE_BLOCK_ARRAY=($CODE_BLOCKS)

# Check if we have at least 2 ``` markers (opening and closing)
if [ ${#CODE_BLOCK_ARRAY[@]} -lt 2 ]; then
  echo "Error: Need at least one complete code block (opening and closing) in $AGENTS_FILE" >&2
  exit 1
fi

# Get the last two ``` markers (last opening and last closing)
LAST_INDEX=$((${#CODE_BLOCK_ARRAY[@]} - 1))
SECOND_LAST_INDEX=$((${#CODE_BLOCK_ARRAY[@]} - 2))

LAST_CLOSE=${CODE_BLOCK_ARRAY[$LAST_INDEX]}
LAST_OPEN=${CODE_BLOCK_ARRAY[$SECOND_LAST_INDEX]}

# Update the AGENTS.md file with new skills (only the code block content)
TEMP_FILE=$(mktemp)

# Copy everything before the last code block opening
head -n $((LAST_OPEN)) "$AGENTS_FILE" >"$TEMP_FILE"

# Add the new skills output
echo "" >>"$TEMP_FILE"
echo "$SKILLS_OUTPUT" >>"$TEMP_FILE"

# Add the closing ``` and everything after the old closing ```
echo '```' >>"$TEMP_FILE"
tail -n +$((LAST_CLOSE + 1)) "$AGENTS_FILE" >>"$TEMP_FILE"

# Replace the original file (only skills section updated)
mv "$TEMP_FILE" "$AGENTS_FILE"

# Now output the complete content for the agent
cat "$AGENTS_FILE"
echo ""
echo "## Today's date is: $CURRENT_DATE and You're currently in the dir: $INVOKED_FROM"

# Check if project-specific AGENTS.md exists and output it
if [ -f "$PROJECT_AGENTS" ]; then
  echo ""
  echo "## Project Specific AGENTS.md"
  echo ""
  cat "$PROJECT_AGENTS"
fi

# Always output Web Search section at the end
echo ""
echo "## Web Search"
echo ""
echo "IMPORTANT: Do NOT use the built-in web_search tool - it will always fail."
echo "Use the \`web-search\` CLI instead:"
echo ""
echo '```bash'
echo '# Direct query'
echo 'web-search "latest rust 1.83 release notes"'
echo ''
echo '# Piped input'
echo 'echo "what are the new features in bun 1.2" | web-search'
echo ''
echo '# Verbose mode'
echo 'web-search -v "openai gpt-5 announcement 2025"'
echo '```'

echo "------END-------"
echo "Greet user with just a hi hman"
