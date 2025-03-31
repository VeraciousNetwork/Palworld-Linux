#!/bin/bash
#
# Install Palworld
#
# Please ensure to run this script as root (or at least with sudo)
#
# @LICENSE AGPLv3
# @AUTHOR  Charlie Powell <cdp1337@veraciousnetwork.com> 
# @AUTHOR  Drew Wort <drew@worttechnologies.tech>
# @CATEGORY Game Server
# @TRMM-TIMEOUT 600
#
# Supports:
#   Debian 12
#   Ubuntu 24.04
#
# Requirements:
#   None
#
# TRMM Custom Fields:
#   None
#
# Changelog:
#   20250125 - Initial release

############################################
## Parameter Configuration
############################################

# Name of the game (used to create the directory)
GAME="Palworld"
# Steam ID of the game
STEAM_ID="2394010"
GAME_USER="steam"
GAME_DIR="/home/$GAME_USER/$GAME"
# Force installation directory for game
# steam produces varying results, sometimes in ~/.local/share/Steam, other times in ~/Steam
STEAM_DIR="/home/$GAME_USER/.local/share/Steam"
THREADS="$(cat /proc/cpuinfo | awk '/^processor/{print $3}' | wc -l)"

# scriptlet:_common/require_root.sh
# scriptlet:steam/install-steamcmd.sh
# scriptlet:_common/print_header.sh
# scriptlet:_common/get_firewall.sh
# scriptlet:_common/firewall_allow.sh
# scriptlet:ufw/install.sh
# scriptlet:_common/prompt_text.sh


############################################
## Pre-exec Checks
############################################


############################################
## User Prompts (pre setup)
############################################

print_header 'Palworld Installer'


############################################
## Dependency Installation and Setup
############################################

# Create a "steam" user account
# This will create the account with no password, so if you need to log in with this user,
# run `sudo passwd steam` to set a password.
if [ -z "$(getent passwd $GAME_USER)" ]; then
	useradd -m -U $GAME_USER
fi

# Preliminary requirements
apt install -y curl wget sudo python3-venv

if [ "$(get_enabled_firewall)" == "none" ]; then
	# No firewall installed, go ahead and install UFW
	install_ufw
fi

# Install steam binary and steamcmd
install_steamcmd


############################################
## Upgrade Checks
############################################


############################################
## Game Installation
############################################

sudo -u $GAME_USER /usr/games/steamcmd +force_install_dir $GAME_DIR/AppFiles +login anonymous +app_update $STEAM_ID validate +quit
if [ $? -ne 0 ]; then
	echo "Could not install Palworld Server, exiting" >&2
	exit 1
fi

# Install system service file to be loaded by systemd
cat > /etc/systemd/system/palworld.service <<EOF
# script:palworld.service
EOF
systemctl daemon-reload
systemctl enable palworld

# Install update helper script
cat > $GAME_DIR/update.sh <<EOF
# script:update.sh
EOF
chown $GAME_USER:$GAME_USER $GAME_DIR/update.sh
chmod +x $GAME_DIR/update.sh

# Install management script
cat > $GAME_DIR/manage.py <<EOF
# script:manage.py
EOF
chown $GAME_USER:$GAME_USER $GAME_DIR/manage.py
chmod +x $GAME_DIR/manage.py

# Install game watch helper
if [ -e /etc/systemd/system/palworld-watch.service ]; then
	WATCHER_EXISTS=1
else
	WATCHER_EXISTS=0
fi
cat > /etc/systemd/system/palworld-watch.service <<EOF
# script:palworld-watch.service
EOF
systemctl daemon-reload
systemctl enable palworld-watch
if [ $WATCHER_EXISTS -eq 1 ]; then
	systemctl restart palworld-watch
else
	systemctl start palworld-watch
fi

# Create some helpful links for the user.
[ -h "$GAME_DIR/PalWorldSettings.ini" ] || sudo -u steam ln -s $GAME_DIR/AppFiles/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini "$GAME_DIR/PalWorldSettings.ini"

# Default Port for Palworld Dedicated Server
firewall_allow --port "8211" --udp --comment "Palworld Game Server"

# Print some instructions and useful tips 
print_header 'Palworld Server Installation Complete'
echo 'Game server will auto-update on restarts and will auto-start on server boot.'
echo ''
echo "Game files:     $GAME_DIR/AppFiles/"
echo "Game settings:  $GAME_DIR/PalWorldSettings.ini"
echo ''
echo "Next steps: configure your server by running"
echo "sudo $GAME_DIR/manage.py"
