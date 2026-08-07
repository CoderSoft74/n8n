#!/bin/bash
# Replace GitLab tokens in all files
find . -type f \( -name "*.json" -o -name "*.md" -o -name "*.OLD" -o -name "*.yml" \) -exec grep -l "glpat-" {} \; 2>/dev/null | while read file; do
    sed -i 's/glpat-[a-zA-Z0-9_\-]*/REPLACE_WITH_YOUR_GITLAB_TOKEN/g' "$file"
done
