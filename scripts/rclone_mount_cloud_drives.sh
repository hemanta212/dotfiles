#!/bin/bash

# Common flags for rclone mount
common_flags="--buffer-size 64M --vfs-read-ahead 512M --vfs-cache-mode full --vfs-cache-max-age 168h0m0s --vfs-cache-max-size 100G --vfs-cache-poll-interval 30s --vfs-write-back 5s --daemon"

# List of rclone remotes
declare -a remotes=("GdriveHS" "Mega" "OneDriveBloom" "OneDriveEdu" "OneDriveHs")

# Ask for the password
echo "Rclone pass: "
read -s rclone_password

# Export the password to an environment variable used by rclone
export RCLONE_CONFIG_PASS=$rclone_password

# Loop through each remote and mount
for remote in "${remotes[@]}"; do
	mount_path="$HOME/rdrives/$remote"

	echo ":: Mounting $remote to $mount_path..."
	mkdir -p "$mount_path"
	echo $RCLONE_CONFIG_PASS | rclone mount $remote: "$mount_path" --volname "$remote" $common_flags
done

# Unset the password variable for security
unset RCLONE_CONFIG_PASS

echo "All remotes mounted."
