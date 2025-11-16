# pub-watch Quick Test Guide

## Quick Test Commands

### 1. Full End-to-End Test (Dry Run, No Build)
**Fastest way to test everything**
```bash
cd ~/dev/dotfiles/scripts/tutero/pub-watch

# Clear state
echo '{"processed_commits": {}}' > ~/.cache/scripts/pub-watch/state.json

# Run test
./pub-watch-daemon --once --dry-run --skip-build \
  --test-trigger=917b413146 --test-metadata=43bd63df0c

# Should see:
# ✓ Found: lesson_plan @ 1.27.3
# ✓ Found: skill_info @ 1.6.2
# ✓ Found: learning_library @ 1.176.4
# ✓ Found SHA256 for each package
# ✓ Successfully updated ... in pubspec.lock
# ✓ Changes committed
# ✓ Branch pushed
# ✓ Workflow complete!
```

### 2. Test Package Extraction Only
**Debug metadata parsing**
```bash
./pub-watch-daemon --once --dry-run --skip-build \
  --skip-metadata-wait --test-metadata=43bd63df0c
```

### 3. Test Real PR Creation
**Create actual PR (careful!)**
```bash
# Only run after dry-run succeeds
./pub-watch-daemon --once --skip-build \
  --test-trigger=917b413146 --test-metadata=43bd63df0c

# Will create real PR on hemanta212/schools-app
```

### 4. Test With Build Validation
**Full test including flutter build (takes 2-5 min)**
```bash
./pub-watch-daemon --once --dry-run \
  --test-trigger=917b413146 --test-metadata=43bd63df0c
```

### 5. Live Daemon Test
**Watch for real commits**
```bash
# Start daemon in foreground
./pub-watch-daemon --once

# Or run in background
./pub-watch start

# Check logs
./pub-watch logs -f
```

## Test Commits Reference

### Known Good Commit Pair
```
Watch Repo: MathGaps/learning-library
Apply Repo: hemanta212/schools-app

Trigger Commit:  917b413146663cc1424794a75896b2a32a874e925
- Author: sharmahemanta.212@gmail.com
- Message: fix: Filter warmup with context based on context
- Date: 2025-10-13

Metadata Commit: 43bd63df0c38b0cc6aa375abb91d7a7191e6c6dc
- Author: github-actions[bot]
- Message: chore: Update release metadata [skip ci]
- Date: 2025-10-13 (3 min after trigger)

Packages Updated:
- lesson_plan: 1.27.2 → 1.27.3
- skill_info: 1.6.1 → 1.6.2
- learning_library: 1.176.3 → 1.176.4
```

## Verify Results

### Check Worktree
```bash
cd /tmp/pub-watch-worktrees/hemanta212_schools-app_auto-update-*

# See commit
git show --stat

# See pubspec.lock changes
git diff HEAD~1 pubspec.lock
```

### Check State
```bash
cat ~/.cache/scripts/pub-watch/state.json | jq .
```

### Check Logs
```bash
./pub-watch logs
```

## Common Issues

### Issue: "jq: parse error"
**Cause**: Logging functions output to stdout
**Fix**: Already fixed - all logs go to stderr now

### Issue: "Failed to fetch commit data"
**Debug**:
```bash
# Test API directly
gh api "/repos/MathGaps/learning-library/commits/43bd63df0c"
```

### Issue: "Package not found on pub server"
**Debug**:
```bash
# Test pub server directly
curl -H "Authorization: Bearer readonly54321" \
  "https://pub.tutero.dev/api/packages/lesson_plan/versions/1.27.3"
```

### Issue: "No packages found"
**Debug**:
```bash
# Check metadata commit has pubspec.yaml changes
gh api "/repos/MathGaps/learning-library/commits/43bd63df0c" \
  --jq '.files[] | select(.filename | endswith("pubspec.yaml")) | .filename'
```

## Configuration

### Current Setup
```bash
# View repos
./pub-watch list

# Should show:
# ✓ MathGaps/learning-library → hemanta212/schools-app
#   Author: sharmahemanta.212@gmail.com
```

### Change Configuration
```bash
# Set different author
./pub-watch author MathGaps/learning-library "Hemanta Sharma"

# View config
./pub-watch config

# Change check interval (seconds)
./pub-watch config set check_interval 60
```

## Clean Up

### Remove Test Worktrees
```bash
rm -rf /tmp/pub-watch-worktrees/*
```

### Clear State
```bash
echo '{"processed_commits": {}}' > ~/.cache/scripts/pub-watch/state.json
```

### Remove Test Branches
```bash
cd ~/path/to/schools-app
git branch -D auto-update-*
git push origin --delete auto-update-*
```

## Success Indicators

When test succeeds, you should see:
1. ✓ Three packages extracted
2. ✓ Three SHA256 hashes fetched
3. ✓ Three pubspec.lock updates
4. ✓ One commit created
5. ✓ Branch pushed
6. ✓ PR created (or "would create" in dry-run)

## Performance Benchmarks

- Package extraction: ~2s
- Pub queries (3 packages): ~1s
- Worktree setup: ~4s
- pubspec.lock updates: <1s
- Git commit/push: ~3s
- **Total (no build): ~10s**
- **With build: 2-5 min**

## Help

```bash
./pub-watch-daemon --help
```

## Next Steps After Successful Test

1. ✅ Dry-run test passed
2. → Test real PR creation (remove `--dry-run`)
3. → Test with build validation (remove `--skip-build`)
4. → Test live daemon (run without `--test-*` flags)
5. → Deploy to production
