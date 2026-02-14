# Security Cleanup Required

## What Happened
Your Strava client secret was committed and pushed to the git repository in `app/config/dev.exs`.

## What Has Been Fixed
1. ✅ Created top-level `.gitignore` to exclude macOS files (`.DS_Store`)
2. ✅ Added `config/dev.secret.exs` to app's `.gitignore`
3. ✅ Removed hardcoded secrets from `dev.exs`
4. ✅ Created `dev.secret.exs` (gitignored) with your current credentials
5. ✅ Created `dev.secret.exs.example` template for other developers

## What You Need to Do

### 1. Rotate Your Strava Credentials (IMPORTANT!)
Since the secret was already pushed to git, it's in the repository history. You should:
- Go to your Strava API settings: https://www.strava.com/settings/api
- Delete the current application or regenerate the client secret
- Update the new credentials in `app/config/dev.secret.exs`

### 2. Clean Up Git
```bash
# Stage the changes
git add .gitignore app/.gitignore app/config/dev.exs app/config/dev.secret.exs.example

# Remove .DS_Store from git tracking
git rm --cached .DS_Store

# Commit the security fix
git commit -m "fix: secure Strava credentials and improve gitignore

- Move secrets to dev.secret.exs (gitignored)
- Add top-level gitignore for macOS files
- Create dev.secret.exs.example template
- Remove hardcoded secrets from dev.exs"

# Push the fix
git push
```

### 3. Optional: Remove Secrets from Git History
If you want to completely remove the secret from git history (requires force push):

```bash
# Use git-filter-repo (recommended) or BFG Repo-Cleaner
# WARNING: This rewrites history and requires force push
# Only do this if you understand the implications

# Install git-filter-repo
brew install git-filter-repo

# Remove the old dev.exs from history
git filter-repo --path app/config/dev.exs --invert-paths

# Force push (affects all clones)
git push --force
```

⚠️ **Note**: Rewriting history affects anyone who has cloned the repository.

## How It Works Now
- `dev.exs` imports `dev.secret.exs` if it exists
- `dev.secret.exs` is gitignored and contains your actual credentials
- Other developers copy `dev.secret.exs.example` to `dev.secret.exs` and add their own credentials
- Alternatively, set `STRAVA_CLIENT_ID` and `STRAVA_CLIENT_SECRET` environment variables
