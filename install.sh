#!/bin/sh

# Define the path to the configuration file
CONFIG_FILE="/etc/distrobox/distrobox.ini"
# Define the temporary file for the downloaded dawbox.ini
TEMP_DAWBOX_INI="dawbox.ini"
# Define the marker string to identify DAWbox entries
DAWBOX_MARKER="# DAWbox Configuration - DO NOT EDIT BELOW THIS LINE"
DAWBOX_MARKER_END="# End DAWbox Configuration"

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
