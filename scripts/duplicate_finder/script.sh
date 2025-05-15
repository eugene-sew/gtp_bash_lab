#!/bin/bash

# Duplicate File Finder
# This script scans a specified directory for duplicate files based on their MD5 hash values.
# It identifies files with identical content regardless of their filenames and outputs the results.

# Prompt the user for a directory to scan
read -p "Enter directory to scan  " directory


# Validate that the provided directory exists.
if [ ! -d "$directory" ]; then
    echo "Error: Directory '$directory' not found."
    exit 1
fi

echo -e "\nScanning for duplicate files in '$directory'..."
echo "This may take a while for large directories..."

# Create a temporary file to store hashes for processing.
tempfile=$(mktemp)

# Find all files within the directory, compute their MD5 hashes, and store results in the temporary file.
find "$directory" -type f -exec md5sum {} + > "$tempfile"

# Notify the user about processing duplicates.
echo -e "\nPossible duplicate files (same MD5 hash):"
echo "-----------------------------------------"

# Process the hashes to group files with identical content.
# Logic:
# - Use the hash as the key to store filenames in an array.
# - Count occurrences of each hash to identify duplicates.
awk '{
    # Extract hash and associated filename
    hash = $1
    $1 = ""
    # Group filenames by hash
    files[hash] = files[hash] $0 "\n"
    count[hash]++
} 
END {
    # Output hashes that appear more than once along with their files
    for (hash in files) {
        if (count[hash] > 1) {
            print "Hash " hash " appears " count[hash] " times:"
            printf "%s", files[hash]
            print "-----------------------------------------"
        }
    }
}' "$tempfile"

# Clean up the temporary file to avoid leaving residual data on the system.
rm "$tempfile"

echo -e "\nScan complete."
