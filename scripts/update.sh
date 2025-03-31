#!/bin/bash
#
# Update Palworld Dedicated Server
#
# DYNAMICALLY GENERATED FILE! Edit at your own risk

# compile:noescape
GAME_USER="$GAME_USER"
GAME_DIR="$GAME_DIR"
STEAM_ID="$STEAM_ID"
SERVICE_NAME="palworld"
# compile:escape

# This script is expected to be run as the steam user, (as that is the owner of the game files).
# If another user calls this script, sudo will be used to switch to the steam user.
if [ "$(whoami)" == "$GAME_USER" ]; then
	SUDO_NEEDED=0
else
	SUDO_NEEDED=1
fi

function update_game {
	echo "Running game update"
	if [ "$SUDO_NEEDED" -eq 1 ]; then
		sudo -u $GAME_USER /usr/games/steamcmd +force_install_dir $GAME_DIR/AppFiles +login anonymous +app_update $STEAM_ID validate +quit
	else
		/usr/games/steamcmd +force_install_dir $GAME_DIR/AppFiles +login anonymous +app_update $STEAM_ID validate +quit
	fi

	if [ $? -ne 0 ]; then
		echo "Game update failed!" >&2
		exit 1
	fi
}

# Check if any maps are running; do not update an actively running server.
if [ "$(systemctl is-active $SERVICE_NAME)" == "active" ]; then
	echo "ERROR - $SERVICE_NAME is still running"
	exit 1
fi

update_game
