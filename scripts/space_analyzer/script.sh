#!/bin/bash

# Disk Space Analyzer
# This script shows a tree-like structure of disk usage for directories and files.
# It also provides total disk usage, overall system space usage, and allows sorting and filtering.

# Function to display usage instructions
function usage() {
    echo "Usage: $0 [directory] [-s (sort)] [-f 'filter']"
    echo "  directory: The starting directory for analysis (default is current directory)"
    echo "  -s: Sort results by size"
    echo "  -f 'filter': Filter results to include only files/directories matching the filter"
    exit 1
}

# Function to analyze disk usage and display results
function analyze_disk_usage() {
    local dir=$1
    local sort_flag=$2
    local filter=$3

    # Display overall system disk space
    echo "Overall system disk space:"
    df -h /

    echo
    echo "Total disk usage for $dir:"
    du -sh "$dir"

    echo
    echo "Disk usage breakdown:"

    # Generate and format disk usage data
    du -ah "$dir" | {
        if [[ -n $filter ]]; then
            # Filter results if a filter is specified
            grep "$filter"
        else
            cat
        fi
    } | {
        if [[ $sort_flag == "true" ]]; then
            # Sort by size if sorting is enabled
            sort -hr
        else
            cat
        fi
    }
}

# Default values
directory="."
sort_flag="false"
filter=""

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -s)
            sort_flag="true"
            shift
            ;;
        -f)
            filter="$2"
            shift 2
            ;;
        *)
            directory="$1"
            shift
            ;;
    esac
done

# Check if directory exists
if [[ ! -d $directory ]]; then
    echo "Error: Directory '$directory' does not exist."
    usage
fi

# Perform disk usage analysis
analyze_disk_usage "$directory" "$sort_flag" "$filter"
