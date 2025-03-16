#!/bin/sh

# Define the path to the configuration file
CONFIG_FILE="/etc/distrobox/dawbox.ini"
# Define the temporary file for the downloaded dawbox.ini
TEMP_DAWBOX_INI="dawbox.ini"

# ANSI escape codes for text formatting
ESC="\033"
BOLD="${ESC}[1m"
RESET="${ESC}[0m"
HIGHLIGHT="${ESC}[7m"

# Function to handle DAWbox configuration
dawbox_config() {
  # If we are here, we have permissions or we ran with sudo
  if [ "$1" = "config-sudo" ]; then
    shift
  fi

  # Check if we have write access to the config file's directory
  if [ ! -w "$(dirname "$CONFIG_FILE")" ]; then
    echo "Insufficient permissions to modify $CONFIG_FILE."
    echo "Attempting to run dawbox_config with sudo..."
    sudo "$0" config-sudo "$@"
    return $?
  fi

  # Download the latest dawbox.ini
  curl -sL https://github.com/Messaiga/DAWbox/blob/main/dawbox.ini?raw=true -o "$TEMP_DAWBOX_INI"

    # Create a backup of the config file
    if [ -f "$CONFIG_FILE" ]; then
      cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"
      echo "Backed up $CONFIG_FILE to ${CONFIG_FILE}.bak"
    fi

    # Replace the config file with the new one
    echo "Replacing $CONFIG_FILE with the latest configuration."
    mv "$TEMP_DAWBOX_INI" "$CONFIG_FILE"

}

# Function to check if DAWbox is installed
dawbox_check() {
    if distrobox ls | grep -iq dawbox; then
        echo "DAWbox in already installed."
        return 0
    else
        echo "DAWbox is not installed."
        return 1
    fi
}

# Function to install DAWbox
dawbox_install() {
    # Call the dawbox_config function to execute the configuration logic
    dawbox_config

    #Check if DAWbox is already installed
    dawbox_check
    local check_result=$?

    if [ "$check_result" -eq 0 ]; then
        echo "DAWbox is already installed.  Skipping installation."
        return 0 # DAWbox is already installed, so we are done.
    elif [ "$check_result" -eq 1 ]; then
        echo "Installing DAWbox..."
        distrobox assemble create --file /etc/distrobox/dawbox.ini
        distrobox stop dawbox
        echo "DAWbox installed successfully."
        return 0 #DAWbox was installed.
    else
        echo "Error checking DAWbox status."
        return 1 # Error checking DAWbox status.
    fi
}


# Function to update DAWbox
dawbox_update() {
    # Call the dawbox_config function to execute the configuration logic
    dawbox_config

    #Check if DAWbox is already installed
    dawbox_check
    local check_result=$?

    if [ "$check_result" -eq 0 ]; then
        echo "DAWbox is already installed.  Updating."
        distrobox upgrade dawbox
        return 0 # DAWbox is already installed, we can update it.
    elif [ "$check_result" -eq 1 ]; then
        echo "DAWbox isn't installed, there's nothing to update."
        return 0 # DAWbox is not installed, there's nothing to update.
    else
        echo "Error checking DAWbox status."
        return 1 # Error checking DAWbox status.
    fi
}

# Function to remove DAWbox

dawbox_rm() {
  # Check if DAWbox is installed
  dawbox_check
    local check_result=$?

    if [ "$check_result" -eq 0 ]; then
        echo "Removing DAWbox..."
        distrobox stop dawbox
        distrobox rm dawbox
        return 0 # DAWbox is now removed, so we are done.
    elif [ "$check_result" -eq 1 ]; then
        echo "DAWbox isn't installed, there's nothing to remove."
        return 0 # DAWbox is not installed, so we are done.
    else
        echo "Error removing DAWbox."
        return 1 # Error checking DAWbox status.
    fi
}

# Function to prompt user for action
dawbox_prompt() {
    while true; do
        echo "Welcome to the DAWbox installer!"
        echo "Please choose an option:"
        echo "  1) Check if DAWbox is installed"
        echo "  2) Install DAWbox"
        echo "  3) Update DAWbox"
        echo "  4) Remove DAWbox"
        echo "  5) Exit"
        read -p "Enter your choice (1-5): " choice

        case "$choice" in
            1)
                dawbox_check
                return 0
                ;;
            2)
                dawbox_install
                return 0
                ;;
            3)
                dawbox_update
                return 0
                ;;
            4)
                dawbox_rm 
                return 0
                ;;
            5)
                echo "Exiting..."
                return 0
                ;;
            *)
                echo "Invalid choice. Please enter 1, 2, 3, 4, or 5"
                ;;
        esac
    done
}

# Check if the script was called with the "config-sudo" argument
if [ "$1" = "config-sudo" ]; then
  dawbox_config config-sudo
  exit 0
fi

# Check if the script was called with the "config" argument
if [ "$1" = "config" ]; then
  dawbox_config
  exit 0
fi

# Call the dawbox_prompt function to start the interactive process
dawbox_prompt

exit 0
