# Deployment Guide

## Security First

**IMPORTANT**: This repository is configured to NEVER commit sensitive information to git.

### Protected Files
- `deploy.sh` - Contains deployment logic (but NO secrets)
- `.deploy-env` - Contains your actual credentials (NOT in git)
- SSH keys and certificates

### Safety Features
1. **Pre-commit hook** - Prevents accidentally committing `deploy.sh` or sensitive files
2. **`.gitignore`** - Protects all sensitive files and patterns
3. **No hardcoded secrets** - Script requires environment variables
4. **Redacted logging** - Script doesn't log sensitive information

## Setup

1. **Create your `.deploy-env` file** (copy from example):
   ```bash
   cp .deploy-env.example .deploy-env
   ```

2. **Edit `.deploy-env`** with your actual credentials:
   ```bash
   export ASTRO_SYNC_HOST="your-username@your-domain.com"
   export ASTRO_SYNC_DEST="public_html/"
   export ASTRO_SYNC_SSH_KEY="$HOME/.ssh/your-ssh-key"
   export ASTRO_SYNC_SSH_PORT="18765"
   ```

3. **Verify `.deploy-env` is ignored**:
   ```bash
   git check-ignore .deploy-env
   # Should output: .deploy-env
   ```

## Usage

The `deploy.sh` script will automatically source `.deploy-env` if it exists, or you can export variables manually:

```bash
# Option 1: Use .deploy-env (recommended)
./deploy.sh

# Option 2: Export variables manually
export ASTRO_SYNC_HOST="..."
export ASTRO_SYNC_DEST="..."
export ASTRO_SYNC_SSH_KEY="..."
./deploy.sh
```

## What Gets Protected

- ✅ `deploy.sh` - In `.gitignore`, pre-commit hook prevents commits
- ✅ `.deploy-env` - In `.gitignore`, never committed
- ✅ SSH keys - Pattern matching in `.gitignore`
- ✅ Environment files - All `.env*` patterns ignored
- ✅ Script doesn't log secrets - Sensitive info is redacted in output

## If You Accidentally Commit Secrets

If secrets ever get committed:

1. **Immediately rotate credentials** (SSH keys, passwords, etc.)
2. **Remove from git history** using `git filter-branch` or BFG Repo-Cleaner
3. **Force push** (coordinate with team if shared repo)

## Troubleshooting

**Pre-commit hook not working?**
```bash
chmod +x .git/hooks/pre-commit
```

**Script says variables are missing?**
- Check that `.deploy-env` exists and has correct values
- Or export variables manually before running script

