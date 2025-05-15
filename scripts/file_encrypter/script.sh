#!/bin/bash

# File Encryption/Decryption Tool
# --------------------------------
# This script provides an interactive menu to encrypt or decrypt files
# using OpenSSL AES-256-CBC with PBKDF2 key derivation.

# --- Configuration ---
# Suffixes and extension for encrypted/decrypted output files
ENCRYPTED_SUFFIX="_encrypted"
DECRYPTED_SUFFIX="_decrypted"
ENCRYPTED_EXTENSION=".enc"

# --- Functions ---

# encrypt_file: encrypts a given input file to an .enc file next to it
# Usage: encrypt_file <path-to-input-file> <password>
encrypt_file() {
  # Resolve absolute path and extract password
  local input_path
  input_path=$(realpath "$1") || return 1
  local password="$2"

  # Prepare output filename with encryption suffix
  local filename=$(basename "$input_path")
  local filename_without_ext="${filename%.*}"
  local output_file="${filename_without_ext}${ENCRYPTED_SUFFIX}${ENCRYPTED_EXTENSION}"
  output_file="$(dirname "$input_path")/$output_file"

  # Validate input and password
  if [ ! -f "$input_path" ]; then
    echo "Error: Input file '$input_path' not found."
    return 1
  fi
  if [ -z "$password" ]; then
    echo "Error: Password cannot be empty."
    return 1
  fi

  # Perform encryption with salt and PBKDF2 iterations
  echo "Encrypting '$input_path' → '$output_file'..."
  openssl aes-256-cbc -salt -pbkdf2 -iter 10000 \
    -in "$input_path" -out "$output_file" -k "$password"

  # Report result
  if [ $? -eq 0 ]; then
    echo "✅ Encryption successful: '$output_file'"
  else
    echo "❌ Encryption failed."
    return 1
  fi
}

# decrypt_file: decrypts a .enc file back to a plaintext file
# Usage: decrypt_file <path-to-encrypted-file.enc> <password>
decrypt_file() {
  # Resolve absolute path and extract password
  local input_path
  input_path=$(realpath "$1") || return 1
  local password="$2"

  # Ensure file has correct .enc extension
  local filename=$(basename "$input_path")
  if [[ "$filename" != *"$ENCRYPTED_EXTENSION" ]]; then
    echo "Error: Input file '$input_path' must end with '$ENCRYPTED_EXTENSION'."
    return 1
  fi

  # Build output filename with decrypted suffix
  local base_name="${filename%$ENCRYPTED_EXTENSION}"
  local output_file="${base_name}${DECRYPTED_SUFFIX}"
  output_file="$(dirname "$input_path")/$output_file"

  # Validate input and password
  if [ ! -f "$input_path" ]; then
    echo "Error: Input file '$input_path' not found."
    return 1
  fi
  if [ -z "$password" ]; then
    echo "Error: Password cannot be empty."
    return 1
  fi

  # Perform decryption with PBKDF2 iterations
  echo "Decrypting '$input_path' → '$output_file'..."
  openssl aes-256-cbc -d -salt -pbkdf2 -iter 10000 \
    -in "$input_path" -out "$output_file" -k "$password"

  # Report result
  if [ $? -eq 0 ]; then
    echo "✅ Decryption successful: '$output_file'"
  else
    echo "❌ Decryption failed. Check your password and that the file is not corrupted."
    return 1
  fi
}

# --- Main Interactive Loop ---
# Presents a simple menu for user actions
while true; do
  cat <<- MENU

    File Encryption/Decryption Tool
    --------------------------------
    1. Encrypt a file
    2. Decrypt a file
    3. Exit

MENU
  read -p "Choose an option (1-3): " choice

  case "$choice" in
    1)
      read -p "Enter path of file to encrypt: " encrypt_path
      if [ -f "$encrypt_path" ]; then
        read -s -p "Enter password: " encrypt_password
        echo
        encrypt_file "$encrypt_path" "$encrypt_password"
      else
        echo "Error: File not found."
      fi
      ;;

    2)
      read -p "Enter path of file to decrypt: " decrypt_path
      if [ -f "$decrypt_path" ]; then
        read -s -p "Enter password: " decrypt_password
        echo
        decrypt_file "$decrypt_path" "$decrypt_password"
      else
        echo "Error: File not found."
      fi
      ;;

    3)
      echo "Exiting tool."
      break
      ;;

    *)
      echo "Invalid option. Please enter 1, 2, or 3."
      ;;
  esac
done

exit 0
