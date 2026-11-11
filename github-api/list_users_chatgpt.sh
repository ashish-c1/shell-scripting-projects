#!/bin/bash

# Check whether required commands are installed
for cmd in gh jq; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: $cmd is not installed."
        exit 1
    fi
done

# Check GitHub authentication
if ! gh auth status >/dev/null 2>&1; then
    echo "Error: You are not authenticated with GitHub."
    echo "Run: gh auth login"
    exit 1
fi

# Get input from user
read -r -p "Enter GitHub organization name: " ORG
read -r -p "Enter repository name: " REPO

# Validate input
if [[ -z "$ORG" || -z "$REPO" ]]; then
    echo "Error: Organization and repository names are required."
    exit 1
fi

echo ""
echo "Fetching collaborators for $ORG/$REPO..."
echo "------------------------------------------"

# GitHub API endpoint
ENDPOINT="repos/$ORG/$REPO/collaborators?affiliation=all&per_page=100"

# Fetch all pages of collaborators
if ! RESPONSE=$(gh api --paginate --slurp "$ENDPOINT"); then
    echo "Error: Unable to retrieve repository collaborators."
    echo "Check repository name, access permissions and authentication."
    exit 1
fi

# Count collaborators
COUNT=$(jq '[.[][]] | length' <<< "$RESPONSE")

if [[ "$COUNT" -eq 0 ]]; then
    echo "No collaborators found."
    exit 0
fi

# Display usernames and access levels
echo "Repository: $ORG/$REPO"
echo "Total users: $COUNT"
echo ""

jq -r '
    (["USERNAME", "ACCESS LEVEL"]),
    (.[][] | [.login, (.role_name // "unknown")])
    | @tsv
' <<< "$RESPONSE" | column -t -s $'\t'

echo ""
echo "Completed successfully."
