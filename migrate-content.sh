#!/bin/bash
# Migration helper script for hugo-tufte theme

set -e

echo "=== Hugo Tufte Theme Migration Script ==="
echo ""

# Check if running in correct directory
if [ ! -f "hugo.toml" ] && [ ! -f "config.toml" ] && [ ! -f "config.yaml" ]; then
    echo "Error: No Hugo config file found. Run this from your Hugo site root."
    exit 1
fi

SOURCE_DIR="${1:-content/post}"
DEST_DIR="content/post"

echo "Source: $SOURCE_DIR"
echo "Destination: $DEST_DIR"
echo ""

# Create destination directory
mkdir -p "$DEST_DIR"

# Function to fix headings in markdown files
fix_headings() {
    local file="$1"
    local temp_file=$(mktemp)
    
    # Read file and process
    awk '
    /^```/ { in_code = !in_code }
    !in_code && /^# [A-Z]/ {
        # Convert h1 to h2 for section headings (capitalized, outside code blocks)
        print "#" $0
        next
    }
    { print }
    ' "$file" > "$temp_file"
    
    mv "$temp_file" "$file"
}

# Function to add image field to frontmatter if images referenced
add_image_field() {
    local file="$1"
    local temp_file=$(mktemp)
    
    # Check if file has image reference but no image frontmatter
    if grep -q "!\[.*\](.*images/" "$file" && ! grep -q "^image:" "$file"; then
        # Extract first image path
        local img_path=$(grep -oP '!\[.*?\]\(\K[^)]+' "$file" | grep "images/" | head -1)
        if [ -n "$img_path" ]; then
            # Add image field after date field
            awk -v img="$img_path" '
            /^date:/ {
                print
                print "image: \"" img "\""
                next
            }
            { print }
            ' "$file" > "$temp_file"
            mv "$temp_file" "$file"
            echo "  Added image: $img_path"
        fi
    fi
}

# Function to ensure proper frontmatter
fix_frontmatter() {
    local file="$1"
    local temp_file=$(mktemp)
    
    # Check if frontmatter exists
    if ! head -1 "$file" | grep -q "^---"; then
        # Add minimal frontmatter
        local title=$(basename "$file" .md | sed 's/-/ /g' | sed 's/\b\w/\u&/g')
        local date=$(date +%Y-%m-%d)
        
        echo "---" > "$temp_file"
        echo "title: \"$title\"" >> "$temp_file"
        echo "date: ${date}T00:00:00+00:00" >> "$temp_file"
        echo "draft: false" >> "$temp_file"
        echo "---" >> "$temp_file"
        echo "" >> "$temp_file"
        cat "$file" >> "$temp_file"
        mv "$temp_file" "$file"
        echo "  Added frontmatter"
    fi
}

# Process each markdown file
for file in "$SOURCE_DIR"/*.md; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        echo "Processing: $filename"
        
        # Copy to destination
        cp "$file" "$DEST_DIR/$filename"
        
        # Fix frontmatter
        fix_frontmatter "$DEST_DIR/$filename"
        
        # Fix headings
        fix_headings "$DEST_DIR/$filename"
        
        # Add image field if needed
        add_image_field "$DEST_DIR/$filename"
        
        echo "  ✓ Done"
    fi
done

echo ""
echo "=== Migration Complete ==="
echo ""
echo "Next steps:"
echo "1. Review migrated content in $DEST_DIR/"
echo "2. Run 'hugo server' to test"
echo "3. Check heading hierarchy on posts"
echo "4. Verify images are in static/images/"
