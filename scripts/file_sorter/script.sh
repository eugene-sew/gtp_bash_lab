#!/bin/bash

# File Sorter
# This script organizes files in a given directory into subfolders based on file types.
# Subfolders include: Documents, Images, Videos, Audio, and Logs.

# Prompt the user for the source directory.
read -p "Enter path to source directory: " directory

if [ ! -d $directory ]; then
    echo "Directory not found"
    exit 1;
fi


echo "Sorting files in $directory ..."
echo "directory structure ..."
tree -L 2 $directory

echo "sorting items..."

# create the folders to sort things into
mkdir -p "$directory/Documents" "$directory/Images" "$directory/Videos" "$directory/Audio" "$directory/Logs"

# find the files first and move all the related files into the specified folder

find $directory -maxdepth 1 -type f \( -iname "*.pdf" -o -iname "*.doc" -o -iname "*.docx" -o -iname "*.pptx" -o -iname "*.xlsx" \) -exec mv {} "$directory/Documents/" \;

# Move image files into the Images folder 
find $directory -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) -exec mv {} "$directory/Images/" \;

# Move video files into the Videos folder
find $directory -maxdepth 1 -type f \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.avi" -o -iname "*.mov" \) -exec mv {} "$directory/Videos/" \;

# Move video files into the Videos folder
find $directory -maxdepth 1 -type f \( -iname "*.mp3" -o -iname "*.ogg" -o -iname "*.wave" \) -exec mv {} "$directory/Audio/" \;

# Move video files into the Logs folder
find $directory -maxdepth 1 -type f \( -iname "*.log" -o -iname "*.txt" \) -exec mv {} "$directory/Logs/" \;

echo "Files have been organized into subfolders."
echo "New structure ... "
tree -L 2 $directory
