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
dawbox-config() {

  # Check if we have write access to the config file's directory
  if [ ! -w "$(dirname "$CONFIG_FILE")" ]; then
    echo "Insufficient permissions to modify $CONFIG_FILE."
    echo "Attempting to re-run with sudo..."
    sudo "$0" "$@"
    exit $?
  fi

  # Download the latest dawbox.ini
  curl -s https://github.com/Messaiga/DAWbox/blob/main/dawbox.ini?raw=true -o "$TEMP_DAWBOX_INI"

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
dawbox-check() {
    if distrobox ls | grep -iq dawbox; then
        echo "DAWbox in already installed."
        return 0
    else
        echo "DAWbox is not installed."
        return 1
    fi
}

# Function to install DAWbox
dawbox-install() {

    # Call the dawbox-config function to execute the configuration logic
    dawbox-config

    #Check if DAWbox is already installed
    dawbox-check
    local check_result=$?

    if [ "$check_result" -eq 0 ]; then
        echo "DAWbox is already installed.  Skipping installation."
        return 0 # DAWbox is already installed, so we are done.
    elif [ "$check_result" -eq 1 ]; then
        echo "Installing DAWbox..."
        distrobox assemble create --file=/etc/distrobox/dawbox.ini
        echo "DAWbox installed successfully."
        return 0 #DAWbox was installed.
    else
        echo "Error checking DAWbox status."
        return 1 # Error checking DAWbox status.
    fi
}

# Function to prompt user for action
dawbox-prompt() {
    local options=("Check if DAWbox is installed" "Install DAWbox" "Exit")
    local selected=0
    local key

    # Function to redraw the menu
    redraw_menu() {
        clear
        echo "Welcome to the DAWbox installer!"
        echo "Please choose an option:"
        for i in "${!options[@]}"; do
            if [ "$i" -eq "$selected" ]; then
                echo -e "${HIGHLIGHT}  ${options[$i]}${RESET}"
            else
                echo "  ${options[$i]}"
            fi
        done
    }

    # Main loop
    while true; do
        redraw_menu

        # Read a single character without waiting for Enter
        read -rsn1 key

        case "$key" in
            $'\x1b') # Escape sequence (arrow keys)
                read -rsn2 key
                case "$key" in
                    [A) # Up arrow
                        selected=$(( (selected - 1 + ${#options[@]}) % ${#options[@]} ))
                        ;;
                    [B) # Down arrow
                        selected=$(( (selected + 1) % ${#options[@]} ))
                        ;;
                esac
                ;;
            $'\x0a') # Enter key
                case "$selected" in
                    0)
                        dawbox-check
                        ;;
                    1)
                        dawbox-install
                        ;;
                    2)
                        echo "Exiting..."
                        return 0
                        ;;
                esac
                ;;
            $'\x03') # Ctrl+C
                echo "^C"
                echo "Exiting..."
                return 0
                ;;
        esac
    done
}

# Call the dawbox-prompt function to start the interactive process
dawbox-prompt

exit 0
