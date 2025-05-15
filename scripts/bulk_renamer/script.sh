#!/bin/bash

# Bulk File Renamer
# This script allows users to rename files in bulk within a specified directory.
# Users can perform various operations like adding prefixes/suffixes, counters, date stamps,
# or converting filenames to uppercase/lowercase. The script ensures safety by skipping itself 
# and employs logic to handle files with/without extensions appropriately.

# Prompt user for a directory to process
read -p "Enter directory path (leave empty for current directory): " directory


# Validate the directory path before proceeding.
if [ ! -d "$directory" ]; then
    echo "Error: Directory '$directory' not found."
    exit 1
fi

# Navigate to the specified directory.
cd "$directory" || exit 1

# Display a menu of renaming operations for the user to choose from.
echo ""
echo "Select an operation:"
echo "1) Add prefix"
echo "2) Add suffix"
echo "3) Add counter (to existing name)"
echo "4) Add counter with new base name"
echo "5) Add date"
echo "6) Convert to uppercase"
echo "7) Convert to lowercase"
echo "0) Exit"
echo ""

# Capture the user's choice.
read -p "Enter your choice (0-7): " choice

case $choice in
    1)
        # Add a specified prefix to all filenames.
        read -p "Enter prefix to add: " prefix
        for file in *; do
            if [ -f "$file" ] && [ "$file" != "$0" ]; then
                mv -n "$file" "${prefix}${file}"
            fi
        done
        echo "Added prefix '$prefix' to all files."
        ;;
    2)
        # Add a specified suffix to all filenames, preserving extensions.
        read -p "Enter suffix to add: " suffix
        for file in *; do
            if [ -f "$file" ] && [ "$file" != "$0" ]; then
                # Handle files with and without extensions.
                filename="${file%.*}"
                extension="${file##*.}"
                if [ "$filename" = "$extension" ]; then
                    mv -n "$file" "${file}${suffix}"
                else
                    mv -n "$file" "${filename}${suffix}.${extension}"
                fi
            fi
        done
        echo "Added suffix '$suffix' to all files."
        ;;
    3)
        # Add a numeric counter to each file name while retaining original filenames.
        counter=1
        read -p "Enter counter format (e.g., '_', '-', leave empty for no separator): " separator
        for file in *; do
            if [ -f "$file" ] && [ "$file" != "$0" ]; then
                filename="${file%.*}"
                extension="${file##*.}"
                if [ "$filename" = "$extension" ]; then
                    mv -n "$file" "${file}${separator}${counter}"
                else
                    mv -n "$file" "${filename}${separator}${counter}.${extension}"
                fi
                ((counter++))
            fi
        done
        echo "Added counter to all files."
        ;;
    4)
        # Replace existing filenames with a new base name and counter.
        read -p "Enter new base name: " newname
        counter=1
        read -p "Enter counter format (e.g., '_', '-', leave empty for no separator): " separator
        for file in *; do
            if [ -f "$file" ] && [ "$file" != "$0" ]; then
                # Generate new filenames based on the provided base name and counter.
                extension="${file##*.}"
                if [ "$file" = "$extension" ]; then
                    mv -n "$file" "${newname}${separator}${counter}"
                else
                    mv -n "$file" "${newname}${separator}${counter}.${extension}"
                fi
                ((counter++))
            fi
        done
        echo "Renamed all files to '$newname' with counter."
        ;;
    5)
        # Append a date stamp to filenames. User chooses the date format.
        read -p "Enter date format (1=YYYYMMDD, 2=DD-MM-YYYY, 3=MMDDYY): " dateformat
        case $dateformat in
            1) date_str=$(date +"%Y%m%d") ;;
            2) date_str=$(date +"%d-%m-%Y") ;;
            3) date_str=$(date +"%m%d%y") ;;
            *) date_str=$(date +"%Y%m%d") ;; # Default format
        esac
        
        # Add the date string to filenames while retaining extensions.
        for file in *; do
            if [ -f "$file" ] && [ "$file" != "$0" ]; then
                filename="${file%.*}"
                extension="${file##*.}"
                if [ "$filename" = "$extension" ]; then
                    mv -n "$file" "${file}_${date_str}"
                else
                    mv -n "$file" "${filename}_${date_str}.${extension}"
                fi
            fi
        done
        echo "Added date '$date_str' to all files."
        ;;
    6)
        # Convert all filenames to uppercase.
        for file in *; do
            if [ -f "$file" ] && [ "$file" != "$0" ]; then
                newname=$(echo "$file" | awk '{print toupper($0)}')
                if [ "$file" != "$newname" ]; then
                    mv -n "$file" "$newname"
                fi
            fi
        done
        echo "Converted filenames to uppercase."
        ;;
    7)
        # Convert all filenames to lowercase.
        for file in *; do
            if [ -f "$file" ] && [ "$file" != "$0" ]; then
                newname=$(echo "$file" | awk '{print tolower($0)}')
                if [ "$file" != "$newname" ]; then
                    mv -n "$file" "$newname"
                fi
            fi
        done
        echo "Converted filenames to lowercase."
        ;;
    0)
        # Exit the program without performing any operations.
        echo "Exiting without changes."
        exit 0
        ;;
    *)
        # Handle invalid menu options.
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

echo "Rename completed"
