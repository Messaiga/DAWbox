#!/bin/sh

# Define the path to the configuration file
CONFIG_FILE="/etc/distrobox/dawbox.ini"
# Define the temporary file for the downloaded dawbox.ini
TEMP_DAWBOX_INI="dawbox.ini"
# Define the marker string to identify DAWbox entries
DAWBOX_MARKER="# DAWbox Configuration - DO NOT EDIT BELOW THIS LINE"
DAWBOX_MARKER_END="# End DAWbox Configuration"

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

  # Check if the configuration file exists, create it if it doesn't
  if [ ! -f "$CONFIG_FILE" ]; then
    echo "Creating $CONFIG_FILE"
    touch "$CONFIG_FILE"
  fi

  # Check if the marker exists in the config file
  if ! grep -qF "$DAWBOX_MARKER" "$CONFIG_FILE"; then
    echo "Adding DAWbox marker to $CONFIG_FILE"
    echo "$DAWBOX_MARKER" >> "$CONFIG_FILE"
  fi

  # Extract the DAWbox section from the config file
  existing_dawbox_config=$(sed -n "/$DAWBOX_MARKER/,/$DAWBOX_MARKER_END/p" "$CONFIG_FILE")

  # Extract the content of the downloaded dawbox.ini
  new_dawbox_config=$(cat "$TEMP_DAWBOX_INI")

  # Compare the existing and new DAWbox configurations
  if [ "$existing_dawbox_config" != "$new_dawbox_config" ]; then
    echo "DAWbox configuration differs, updating $CONFIG_FILE"

    # Create a backup of the config file
    cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"
    echo "Backed up $CONFIG_FILE to ${CONFIG_FILE}.bak"

    # Remove the old DAWbox section
    sed -i "/$DAWBOX_MARKER/,/$DAWBOX_MARKER_END/d" "$CONFIG_FILE"

    # Append the new DAWbox configuration
    echo "$new_dawbox_config" >> "$CONFIG_FILE"

    # Check if the end marker already exists before appending it
    if ! grep -qF "$DAWBOX_MARKER_END" "$CONFIG_FILE"; then
      echo "$DAWBOX_MARKER_END" >> "$CONFIG_FILE"
    fi
  else
    echo "DAWbox configuration is up to date, no changes needed."
  fi

  # Clean up the temporary dawbox.ini file
  rm "$TEMP_DAWBOX_INI"
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

# Function to prompt user for action
dawbox_prompt() {
    while true; do
        echo "Welcome to the DAWbox installer!"
        echo "Please choose an option:"
        echo "  1) Check if DAWbox is installed"
        echo "  2) Install DAWbox"
        echo "  3) Exit"
        read -p "Enter your choice (1-3): " choice

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
                echo "Exiting..."
                return 0
                ;;
            *)
                echo "Invalid choice. Please enter 1, 2, or 3."
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
