#!/usr/bin/env bash
# One-off script: creates the GitHub repo, pushes the site and switches on GitHub Pages.
# Requires the GitHub CLI (gh). Run from inside this folder: bash deploy.sh
set -euo pipefail

REPO_NAME="snuffel-site"

# 1. Install gh if missing (Ubuntu)
if ! command -v gh >/dev/null 2>&1; then
  echo "Installing GitHub CLI..."
  sudo apt update && sudo apt install -y gh
fi

# 2. Log in once in the browser if not already authenticated
gh auth status >/dev/null 2>&1 || gh auth login --web --git-protocol ssh

# 3. Refuse to publish while placeholders are still in the page
if grep -qE 'YOUR@EMAIL|YOURCALUSER|32000000000|\[BCE' index.html; then
  echo "index.html still contains placeholders (email, Cal.com user, WhatsApp number or BCE number)."
  read -rp "Publish anyway? [y/N] " ok
  [[ "$ok" == "y" ]] || exit 1
fi

# 4. Commit everything locally
git init -q -b main 2>/dev/null || true
git add .
git commit -qm "Snuffel site" || echo "Nothing new to commit"

# 5. Create the public repo on GitHub and push (skips creation if it already exists)
if ! gh repo view "$REPO_NAME" >/dev/null 2>&1; then
  gh repo create "$REPO_NAME" --public --source=. --remote=origin --push
else
  git push -u origin main
fi

# 6. Switch on GitHub Pages, serving the main branch from the root folder
OWNER=$(gh api user --jq .login)
gh api -X POST "repos/$OWNER/$REPO_NAME/pages" \
  -f "source[branch]=main" -f "source[path]=/" >/dev/null 2>&1 \
  || echo "Pages may already be enabled, carrying on."

echo
echo "Done. The site will be live in a minute or two at:"
echo "https://$OWNER.github.io/$REPO_NAME/"
