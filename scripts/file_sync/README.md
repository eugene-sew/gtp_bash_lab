# File Sync

This script synchronizes files between two directories, ensuring both locations have the latest versions of your files. It supports interactive prompts, optional logging, and conflict resolution.

## Files

- `script.sh`: Main script to perform two-way file synchronization with conflict handling and logging options.
- `screenshot/`: Contains images demonstrating the script in action.

## Features

- **Interactive prompts** for local and remote directory paths.
- **Optional logging**: Save sync details to a log file of your choice.
- **Conflict detection and resolution**: Choose to resolve conflicts automatically (by renaming) or manually.
- **Two-way sync**: Ensures both directories have the latest versions of all files.
- **Uses `rsync`** for efficient file transfer and synchronization.

## Usage

Run the script and follow the prompts:

```bash
./script.sh
```

You will be prompted to:

- Enter the path to the LOCAL directory
- Enter the path to the REMOTE directory
- Enable or disable logging (and specify a log file path if enabled)
- Choose whether to handle conflicts automatically (by renaming conflicting files)

### Logging

If enabled, logs are written to the specified file (default: `/var/log/twoway-sync.log`).

### Conflict Resolution

- **Automatic**: Conflicting files are renamed with `.local_conflict` and `.remote_conflict` suffixes.
- **Manual**: The script will notify you of conflicts to resolve manually.

## Screenshot

![Synchronization Process](screenshot/Screenshot%202025-05-15%20at%2015.51.15.png)
_The script is shown synchronizing files between two directories, displaying progress and results to confirm successful sync._
