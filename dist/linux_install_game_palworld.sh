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
#   20250331 - Implement management script ported from ARK SA
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

##
# Simple check to enforce the script to be run as root
if [ $(id -u) -ne 0 ]; then
	echo "This script must be run as root or with sudo!" >&2
	exit 1
fi
##
# Check if the OS is "like" a certain type
#
# ie: "ubuntu" will be like "debian"
function os_like_debian() {
	if [ -f '/etc/os-release' ]; then
		ID="$(egrep '^ID=' /etc/os-release | sed 's:ID=::')"
		LIKE="$(egrep '^ID_LIKE=' /etc/os-release | sed 's:ID_LIKE=::')"

		if [[ "$LIKE" =~ 'debian' ]]; then echo 1; return; fi
		if [[ "$LIKE" =~ 'ubuntu' ]]; then echo 1; return; fi
		if [ "$ID" == 'debian' ]; then echo 1; return; fi
		if [ "$ID" == 'ubuntu' ]; then echo 1; return; fi
	fi

	echo 0
}

##
# Check if the OS is "like" a certain type
#
# ie: "ubuntu" will be like "debian"
function os_like_ubuntu() {
	if [ -f '/etc/os-release' ]; then
		ID="$(egrep '^ID=' /etc/os-release | sed 's:ID=::')"
		LIKE="$(egrep '^ID_LIKE=' /etc/os-release | sed 's:ID_LIKE=::')"

		if [[ "$LIKE" =~ 'ubuntu' ]]; then echo 1; return; fi
		if [ "$ID" == 'ubuntu' ]; then echo 1; return; fi
	fi

	echo 0
}

##
# Check if the OS is "like" a certain type
#
# ie: "ubuntu" will be like "debian"
function os_like_rhel() {
	if [ -f '/etc/os-release' ]; then
		ID="$(egrep '^ID=' /etc/os-release | sed 's:ID=::')"
		LIKE="$(egrep '^ID_LIKE=' /etc/os-release | sed 's:ID_LIKE=::')"

		if [[ "$LIKE" =~ 'rhel' ]]; then echo 1; return; fi
		if [[ "$LIKE" =~ 'fedora' ]]; then echo 1; return; fi
		if [[ "$LIKE" =~ 'centos' ]]; then echo 1; return; fi
		if [ "$ID" == 'rhel' ]; then echo 1; return; fi
		if [ "$ID" == 'fedora' ]; then echo 1; return; fi
		if [ "$ID" == 'centos' ]; then echo 1; return; fi
	fi

	echo 0
}

##
# Check if the OS is "like" a certain type
#
# ie: "ubuntu" will be like "debian"
function os_like_suse() {
	if [ -f '/etc/os-release' ]; then
		ID="$(egrep '^ID=' /etc/os-release | sed 's:ID=::')"
		LIKE="$(egrep '^ID_LIKE=' /etc/os-release | sed 's:ID_LIKE=::')"

		if [[ "$LIKE" =~ 'suse' ]]; then echo 1; return; fi
		if [ "$ID" == 'suse' ]; then echo 1; return; fi
	fi

	echo 0
}

##
# Check if the OS is "like" a certain type
#
# ie: "ubuntu" will be like "debian"
function os_like_arch() {
	if [ -f '/etc/os-release' ]; then
		ID="$(egrep '^ID=' /etc/os-release | sed 's:ID=::')"
		LIKE="$(egrep '^ID_LIKE=' /etc/os-release | sed 's:ID_LIKE=::')"

		if [[ "$LIKE" =~ 'arch' ]]; then echo 1; return; fi
		if [ "$ID" == 'arch' ]; then echo 1; return; fi
	fi

	echo 0
}

##
# Check if the OS is "like" a certain type
#
# ie: "ubuntu" will be like "debian"
function os_like_bsd() {
	if [ "$(uname -s)" == 'FreeBSD' ]; then
		echo 1
	else
		echo 0
	fi
}

##
# Check if the OS is "like" a certain type
#
# ie: "ubuntu" will be like "debian"
function os_like_macos() {
	if [ "$(uname -s)" == 'Darwin' ]; then
		echo 1
	else
		echo 0
	fi
}

##
# Install SteamCMD
function install_steamcmd() {
	echo "Installing SteamCMD..."

	TYPE_DEBIAN="$(os_like_debian)"
	TYPE_UBUNTU="$(os_like_ubuntu)"

	# Preliminary requirements
	if [ "$TYPE_UBUNTU" == 1 ]; then
		add-apt-repository -y multiverse
		dpkg --add-architecture i386
		apt update

		# By using this script, you agree to the Steam license agreement at https://store.steampowered.com/subscriber_agreement/
		# and the Steam privacy policy at https://store.steampowered.com/privacy_agreement/
		# Since this is meant to support unattended installs, we will forward your acceptance of their license.
		echo steam steam/question select "I AGREE" | debconf-set-selections
		echo steam steam/license note '' | debconf-set-selections

		apt install -y steamcmd
	elif [ "$TYPE_DEBIAN" == 1 ]; then
		dpkg --add-architecture i386
		apt update
		apt install -y software-properties-common apt-transport-https dirmngr ca-certificates lib32gcc-s1

		# Enable "non-free" repos for Debian (for steamcmd)
		# https://stackoverflow.com/questions/76688863/apt-add-repository-doesnt-work-on-debian-12
		add-apt-repository -y -U http://deb.debian.org/debian -c non-free-firmware -c non-free
		if [ $? -ne 0 ]; then
			echo "Workaround failed to add non-free repos, trying new method instead"
			apt-add-repository -y non-free
		fi

		# Install steam repo
		curl -s http://repo.steampowered.com/steam/archive/stable/steam.gpg > /usr/share/keyrings/steam.gpg
		echo "deb [arch=amd64,i386 signed-by=/usr/share/keyrings/steam.gpg] http://repo.steampowered.com/steam/ stable steam" > /etc/apt/sources.list.d/steam.list

		# By using this script, you agree to the Steam license agreement at https://store.steampowered.com/subscriber_agreement/
		# and the Steam privacy policy at https://store.steampowered.com/privacy_agreement/
		# Since this is meant to support unattended installs, we will forward your acceptance of their license.
		echo steam steam/question select "I AGREE" | debconf-set-selections
		echo steam steam/license note '' | debconf-set-selections

		# Install steam binary and steamcmd
		apt update
		apt install -y steamcmd
	else
		echo 'Unsupported or unknown OS' >&2
		exit 1
	fi
}
##
# Print a header message
#
function print_header() {
	local header="$1"
	echo "================================================================================"
	printf "%*s\n" $(((${#header}+80)/2)) "$header"
    echo ""
}
##
# Get which firewall is enabled,
# or "none" if none located
function get_enabled_firewall() {
	if [ "$(systemctl is-active firewalld)" == "active" ]; then
		echo "firewalld"
	elif [ "$(systemctl is-active ufw)" == "active" ]; then
		echo "ufw"
	elif [ "$(systemctl is-active iptables)" == "active" ]; then
		echo "iptables"
	else
		echo "none"
	fi
}

##
# Get which firewall is available on the local system,
# or "none" if none located
function get_available_firewall() {
	if systemctl list-unit-files firewalld.service &>/dev/null; then
		echo "firewalld"
	elif systemctl list-unit-files ufw.service &>/dev/null; then
		echo "ufw"
	elif systemctl list-unit-files iptables.service &>/dev/null; then
		echo "iptables"
	else
		echo "none"
	fi
}
##
# Add an "allow" rule to the firewall in the INPUT chain
#
# Arguments:
#   --port <port>       Port(s) to allow
#   --source <source>   Source IP to allow (default: any)
#   --zone <zone>       Zone to allow (default: public)
#   --tcp|--udp         Protocol to allow (default: tcp)
#   --comment <comment> (only UFW) Comment for the rule
#
# Specify multiple ports with `--port '#,#,#'` or a range `--port '#:#'`
function firewall_allow() {
	# Defaults and argument processing
	local PORT=""
	local PROTO="tcp"
	local SOURCE="any"
	local FIREWALL=$(get_available_firewall)
	local ZONE="public"
	local COMMENT=""
	while [ $# -ge 1 ]; do
		case $1 in
			--port)
				shift
				PORT=$1
				;;
			--tcp|--udp)
				PROTO=${1:2}
				;;
			--source|--from)
				shift
				SOURCE=$1
				;;
			--zone)
				shift
				ZONE=$1
				;;
			--comment)
				shift
				COMMENT=$1
				;;
			*)
				PORT=$1
				;;
		esac
		shift
	done

	if [ "$PORT" == "" -a "$ZONE" != "trusted" ]; then
		echo "firewall_allow: No port specified!" >&2
		exit 1
	fi

	if [ "$PORT" != "" -a "$ZONE" == "trusted" ]; then
		echo "firewall_allow: Trusted zones do not use ports!" >&2
		exit 1
	fi

	if [ "$ZONE" == "trusted" -a "$SOURCE" == "any" ]; then
		echo "firewall_allow: Trusted zones require a source!" >&2
		exit 1
	fi

	if [ "$FIREWALL" == "ufw" ]; then
		if [ "$SOURCE" == "any" ]; then
			echo "firewall_allow/UFW: Allowing $PORT/$PROTO from any..."
			ufw allow proto $PROTO to any port $PORT comment "$COMMENT"
		elif [ "$ZONE" == "trusted" ]; then
			echo "firewall_allow/UFW: Allowing all connections from $SOURCE..."
			ufw allow from $SOURCE comment "$COMMENT"
		else
			echo "firewall_allow/UFW: Allowing $PORT/$PROTO from $SOURCE..."
			ufw allow from $SOURCE proto $PROTO to any port $PORT comment "$COMMENT"
		fi
	elif [ "$FIREWALL" == "firewalld" ]; then
		if [ "$SOURCE" != "any" ]; then
			# Firewalld uses Zones to specify sources
			echo "firewall_allow/firewalld: Adding $SOURCE to $ZONE zone..."
			firewall-cmd --zone=$ZONE --add-source=$SOURCE --permanent
		fi

		if [ "$PORT" != "" ]; then
			echo "firewall_allow/firewalld: Allowing $PORT/$PROTO in $ZONE zone..."
			if [[ "$PORT" =~ ":" ]]; then
				# firewalld expects port ranges to be in the format of "#-#" vs "#:#"
				local DPORTS="${PORT/:/-}"
				firewall-cmd --zone=$ZONE --add-port=$DPORTS/$PROTO --permanent
			elif [[ "$PORT" =~ "," ]]; then
				# Firewalld cannot handle multiple ports all that well, so split them by the comma
				# and run the add command separately for each port
				local DPORTS="$(echo $PORT | sed 's:,: :g')"
				for P in $DPORTS; do
					firewall-cmd --zone=$ZONE --add-port=$P/$PROTO --permanent
				done
			else
				firewall-cmd --zone=$ZONE --add-port=$PORT/$PROTO --permanent
			fi
		fi

		firewall-cmd --reload
	elif [ "$FIREWALL" == "iptables" ]; then
		echo "firewall_allow/iptables: WARNING - iptables is untested"
		# iptables doesn't natively support multiple ports, so we have to get creative
		if [[ "$PORT" =~ ":" ]]; then
			local DPORTS="-m multiport --dports $PORT"
		elif [[ "$PORT" =~ "," ]]; then
			local DPORTS="-m multiport --dports $PORT"
		else
			local DPORTS="--dport $PORT"
		fi

		if [ "$SOURCE" == "any" ]; then
			echo "firewall_allow/iptables: Allowing $PORT/$PROTO from any..."
			iptables -A INPUT -p $PROTO $DPORTS -j ACCEPT
		else
			echo "firewall_allow/iptables: Allowing $PORT/$PROTO from $SOURCE..."
			iptables -A INPUT -p $PROTO $DPORTS -s $SOURCE -j ACCEPT
		fi
		iptables-save > /etc/iptables/rules.v4
	elif [ "$FIREWALL" == "none" ]; then
		echo "firewall_allow: No firewall detected" >&2
		exit 1
	else
		echo "firewall_allow: Unsupported or unknown firewall" >&2
		echo 'Please report this at https://github.com/cdp1337/ScriptsCollection/issues' >&2
		exit 1
	fi
}

##
# Install a package with the system's package manager.
#
# Uses Redhat's yum, Debian's apt-get, and SuSE's zypper.
#
# Usage:
#
# ```syntax-shell
# package_install apache2 php7.0 mariadb-server
# ```
#
# @param $1..$N string
#        Package, (or packages), to install.  Accepts multiple packages at once.
#
function package_install (){
	echo "package_install: Installing $*..."

	TYPE_BSD="$(os_like_bsd)"
	TYPE_DEBIAN="$(os_like_debian)"
	TYPE_RHEL="$(os_like_rhel)"
	TYPE_ARCH="$(os_like_arch)"
	TYPE_SUSE="$(os_like_suse)"

	if [ "$TYPE_BSD" == 1 ]; then
		pkg install -y $*
	elif [ "$TYPE_DEBIAN" == 1 ]; then
		apt-get -o Dpkg::Options::="--force-confold" -o Dpkg::Options::="--force-confdef" install -y $*
	elif [ "$TYPE_RHEL" == 1 ]; then
		yum install -y $*
	elif [ "$TYPE_ARCH" == 1 ]; then
		pacman -Syu --noconfirm $*
	elif [ "$TYPE_SUSE" == 1 ]; then
		zypper install -y $*
	else
		echo 'package_install: Unsupported or unknown OS' >&2
		echo 'Please report this at https://github.com/cdp1337/ScriptsCollection/issues' >&2
		exit 1
	fi
}

##
# Install UFW
#
function install_ufw() {
	if [ "$(os_like_rhel)" == 1 ]; then
		# RHEL/CentOS requires EPEL to be installed first
		package_install epel-release
	fi

	package_install ufw

	# Auto-enable a newly installed firewall
	ufw --force enable
	systemctl enable ufw
	systemctl start ufw

	# Auto-add the current user's remote IP to the whitelist (anti-lockout rule)
	local TTY_IP="$(who am i | awk '{print $5}' | sed 's/[()]//g')"
	if [ -n "$TTY_IP" ]; then
		ufw allow from $TTY_IP comment 'Anti-lockout rule based on first install of UFW'
	fi
}
##
# Prompt user for a text response
#
# Arguments:
#   --default="..."   Default text to use if no response is given
#
# Returns:
#   text as entered by user
#
function prompt_text() {
	local DEFAULT=""
	local PROMPT="Enter some text"
	local RESPONSE=""

	while [ $# -ge 1 ]; do
		case $1 in
			--default=*) DEFAULT="${1#*=}";;
			*) PROMPT="$1";;
		esac
		shift
	done

	echo "$PROMPT" >&2
	echo -n '> : ' >&2
	read RESPONSE
	if [ "$RESPONSE" == "" ]; then
		echo "$DEFAULT"
	else
		echo "$RESPONSE"
	fi
}


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
[Unit]
# DYNAMICALLY GENERATED FILE! Edit at your own risk
Description=Palworld Dedicated Server
After=network.target

[Service]
Type=simple
LimitNOFILE=10000
User=$GAME_USER
Group=$GAME_USER
WorkingDirectory=$GAME_DIR/AppFiles
Environment=XDG_RUNTIME_DIR=/run/user/$(id -u $GAME_USER)
Environment="STEAM_COMPAT_CLIENT_INSTALL_PATH=$STEAM_DIR"
ExecStartPre=/usr/games/steamcmd +force_install_dir $GAME_DIR/AppFiles +login anonymous +app_update 2394010 validate +quit
ExecStart=$GAME_DIR/AppFiles/PalServer.sh -publiclobby -useperfthreads -NoAsyncLoadingThread -UseMuilthreadForDS -NumberOfWorkerThreadsServer=$THREADS
ExecStop=$GAME_DIR/manage.py --pre-stop
Restart=on-failure
RestartSec=20s

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable palworld

# Install update helper script
cat > $GAME_DIR/update.sh <<EOF
#!/bin/bash
#
# Update Palworld Dedicated Server
#
# DYNAMICALLY GENERATED FILE! Edit at your own risk

GAME_USER="$GAME_USER"
GAME_DIR="$GAME_DIR"
STEAM_ID="$STEAM_ID"
SERVICE_NAME="palworld"

# This script is expected to be run as the steam user, (as that is the owner of the game files).
# If another user calls this script, sudo will be used to switch to the steam user.
if [ "\$(whoami)" == "\$GAME_USER" ]; then
	SUDO_NEEDED=0
else
	SUDO_NEEDED=1
fi

function update_game {
	echo "Running game update"
	if [ "\$SUDO_NEEDED" -eq 1 ]; then
		sudo -u \$GAME_USER /usr/games/steamcmd +force_install_dir \$GAME_DIR/AppFiles +login anonymous +app_update \$STEAM_ID validate +quit
	else
		/usr/games/steamcmd +force_install_dir \$GAME_DIR/AppFiles +login anonymous +app_update \$STEAM_ID validate +quit
	fi

	if [ \$? -ne 0 ]; then
		echo "Game update failed!" >&2
		exit 1
	fi
}

# Check if any maps are running; do not update an actively running server.
if [ "\$(systemctl is-active \$SERVICE_NAME)" == "active" ]; then
	echo "ERROR - \$SERVICE_NAME is still running"
	exit 1
fi

update_game
EOF
chown $GAME_USER:$GAME_USER $GAME_DIR/update.sh
chmod +x $GAME_DIR/update.sh

# Install management script
cat > $GAME_DIR/manage.py <<EOF
#!/usr/bin/env python3

import os
import sys
from time import sleep
from typing import Union
import subprocess
import readline
import configparser
from urllib import request
from urllib import error as urlerror
import json
import random
from base64 import b64encode
import argparse

here = os.path.dirname(os.path.realpath(__file__))

ICON_ENABLED = '✅'
ICON_STOPPED = '🛑'
ICON_DISABLED = '❌'
ICON_WARNING = '⛔'

# Require sudo / root for starting/stopping the service
IS_SUDO = os.geteuid() == 0


def rl_input(prompt: str, prefill: str = '') -> str:
	"""
	Use Readline to read input with a pre-filled value that can be edited by the user
	:param prompt:
	:param prefill:
	:return: str
	"""
	readline.set_startup_hook(lambda: readline.insert_text(prefill))
	try:
		return input(prompt)  # or raw_input in Python 2
	finally:
		readline.set_startup_hook()


def yn_input(prompt, default='n') -> bool:
	"""
	Ask a yes/no question
	:param prompt:
	:param default:
	:return:
	"""
	if default == 'y':
		prompt += ' [Y/n]: '
	else:
		prompt += ' [y/N]: '

	while True:
		val = input(prompt).lower()
		if val == 'y':
			return True
		elif val == 'n':
			return False
		elif val == '':
			return default == 'y'


def text_width(string: str) -> int:
	"""
	Get the visual width of a string, taking into account extended ASCII characters
	:param string:
	:return:
	"""
	width = 0
	for char in string:
		if ord(char) > 127:
			width += 2
		else:
			width += 1
	return width


def ufw_enable(port: int, protocol: str, comment: str):
	"""
	Open a port in UFW

	:param port:
	:param comment:
	:return:
	"""
	# ufw allow proto tcp to any port 515 comment 'test test'
	params = [
		'ufw',
		'allow',
		'proto', protocol,
		'to', 'any',
		'port', str(port),
		'comment', comment
	]
	subprocess.run(params, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)


def ufw_disable(port: int, protocol: str):
	"""
	Close a port in UFW

	:param port:
	:return:
	"""
	params = [
		'ufw', 'delete',
		'allow',
		'proto', protocol,
		'to', 'any',
		'port', str(port)
	]
	subprocess.run(params, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)


def basic_auth(username, password):
	"""
	Build an authorization token
	:param username:
	:param password:
	:return:
	"""
	# Authorization token: we need to base 64 encode it
	# and then decode it to acsii as python 3 stores it as a byte string
	token = b64encode(f"{username}:{password}".encode('utf-8')).decode("ascii")
	return f'Basic {token}'


def discord_message(message: str) -> str:
	"""
	Get the user-defined message to be sent to Discord, or default if not configured.
	:param message:
	:return:
	"""
	messages = {
		'game_started': ':green_square: Palworld has started',
		'game_stopping': ':small_red_triangle_down: Shutting down Palworld',
		'player_joined': '%s has joined!',
		'player_leveled_up': '%s has leveled up to %s!',
		'player_left': '%s has left the game',
	}
	config = load_config()
	if message in messages:
		# Check if there is a configured value
		configured_message = config['Discord'].get(message, '')
		if configured_message == '':
			# No configured message, use default.
			message = messages[message]
		else:
			message = configured_message

	return message


def discord_alert(message: str, parameters: list = None):
	config = load_config()
	enabled = config['Discord'].get('enabled', '0') == '1'
	webhook = config['Discord'].get('webhook', '')
	message = discord_message(message)

	# Verify the number of '%s' replacements in the string
	# This is important because this is a user-definable string, and users may forget to include '%s'.
	if parameters is not None and message.count('%s') < len(parameters):
		message = message + ' %s' * (len(parameters) - message.count('%s'))

	if parameters is not None:
		message = message % tuple(parameters)

	if enabled and webhook != '':
		print('Sending to discord: ' + message)
		req = request.Request(
			webhook,
			headers={'Content-Type': 'application/json', 'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:135.0) Gecko/20100101 Firefox/135.0'},
			method='POST'
		)
		data = json.dumps({'content': message}).encode('utf-8')
		try:
			with request.urlopen(req, data=data) as resp:
				pass
		except urlerror.HTTPError as e:
			print('Could not notify Discord: %s' % e)
	else:
		print('Would be sent to discord: ' + message)


class GameAPIException(Exception):
	pass


class GameConfig:

	"""
	Configuration file reader for the game server
	"""
	def __init__(self):
		"""
		Initialize the configuration file reader
		:param file:
		"""
		self.file = os.path.join(here, 'AppFiles/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini')
		self.default = os.path.join(here, 'AppFiles/DefaultPalWorldSettings.ini')
		self.header = '/Script/Pal.PalGameWorldSettings'
		self.option_key = 'OptionSettings'
		self.config = {}
		self.configured = False
		self.load()

	def load(self):
		"""
		Load the configuration file
		:return:
		"""
		if os.path.exists(self.file):
			with open(self.file, 'r') as f:
				for line in f.readlines():
					if line.startswith(self.option_key):
						self.configured = True
						# Trim the "OptionSettings=(" prefix and the trailing ")"
						self._parse_options(line.strip()[len(self.option_key) + 2:-1])

		if not self.configured:
			# Load the default configuration file
			with open(self.default, 'r') as f:
				for line in f.readlines():
					if line.startswith(self.option_key):
						# Trim the "OptionSettings=(" prefix and the trailing ")"
						self._parse_options(line.strip()[len(self.option_key) + 2:-1])

	def _parse_options(self, options):
		"""
		Parse the options line to extract each key/value pair
		:param options:
		:return:
		"""
		self.config = {}

		# Use a tokenizer approach for parsing the config line.
		# This is required because some options contain a comma, so we can't just do a quick split.
		buffer = ''
		values = {}
		in_group = False
		group = None
		key = None
		for character in options:
			if character == '=' and not in_group:
				key = buffer.strip()
				buffer = ''
			elif character == ',' and not in_group:
				values[key] = buffer.strip()
				buffer = ''
			elif character == '"' and not in_group:
				in_group = True
				group = character
				buffer += character
			elif character == '(' and not in_group:
				in_group = True
				group = ')'
				buffer += character
			elif group is not None and character == group:
				in_group = False
				buffer += character
			else:
				buffer += character

		# Don't forget the last value.
		if key is not None:
			values[key] = buffer.strip()

		# Check the type of each value so they can be saved back without issue.
		for key, val in values.items():
			if val.lower() == 'true':
				self.config[key] = ['bool', True]
			elif val.lower() == 'false':
				self.config[key] = ['bool', False]
			elif val.isdigit():
				self.config[key] = ['int', int(val)]
			elif val[0] == '"':
				self.config[key] = ['string', val.strip('"')]
			elif val[0] == '(':
				self.config[key] = ['group', val[1:-1].split(',')]
			elif '.' in val:
				self.config[key] = ['float', float(val)]
			else:
				self.config[key] = ['literal', val]

		# # Debug
		# from pprint import pprint
		# pprint(self.config)
		# exit()

	def save(self):
		"""
		Save the configuration file back to disk
		:return:
		"""
		options = []
		for key, val in self.config.items():
			if val[0] == 'bool':
				options.append('%s=%s' % (key, 'True' if val[1] else 'False'))
			elif val[0] == 'int':
				options.append('%s=%s' % (key, val[1]))
			elif val[0] == 'string':
				options.append('%s="%s"' % (key, val[1]))
			elif val[0] == 'float':
				options.append('%s=%s' % (key, val[1]))
			elif val[0] == 'group':
				options.append('%s=(%s)' % (key, ','.join(val[1])))
			else:
				options.append('%s=%s' % (key, val[1]))

		# Debug
		# from pprint import pprint
		# pprint(options)
		# return

		with open(self.file, 'w') as f:
			f.write('[%s]\n' % self.header)
			f.write('%s=(%s)\n' % (self.option_key, ','.join(options)))

	def get(self, key, default=None):
		"""
		Get a configuration value
		:param key:
		:param default:
		:return:
		"""
		return self.config[key][1] if key in self.config else default

	def set(self, key: str, var_type: str, val):
		"""
		Set a configuration value
		:param key:
		:param var_type:
		:param val:
		:return:
		"""
		if var_type not in ['bool', 'int', 'string', 'float', 'group', 'literal']:
			raise ValueError('Invalid variable type')

		if var_type == 'string':
			val = val.replace('"', '')

		self.config[key] = [var_type, val]
		self.save()


class GameService:
	"""
	Service definition and handler
	"""
	def __init__(self):
		"""
		Initialize and load the service definition
		:param file:
		"""
		self.config = GameConfig()
		self.name = 'palworld'

	def _api_cmd(self, cmd: str, method: str = 'GET', data: dict = None):
		method = method.upper()

		if not (self.is_running() or self.is_stopping):
			# If service is not running, don't even try to connect.
			raise GameAPIException('Not running')

		if not self.config.get('RESTAPIEnabled'):
			# No REST API enabled, unable to retrieve any data
			raise GameAPIException('API not enabled')

		req = request.Request(
			'http://127.0.0.1:%s%s' % (str(self.config.get('RESTAPIPort')), cmd),
			headers={
				'Content-Type': 'application/json; charset=utf-8',
				'Accept': 'application/json',
				'Authorization': basic_auth('admin', self.config.get('AdminPassword')),
			},
			method=method
		)
		try:
			if method == 'POST' and data is not None:
				data = bytearray(json.dumps(data), 'utf-8')
				req.add_header('Content-Length', str(len(data)))
				with request.urlopen(req, data) as resp:
					ret = resp.read().decode('utf-8')
					if ret == '':
						return None
					else:
						return json.loads(ret)
			else:
				with request.urlopen(req) as resp:
					ret = resp.read().decode('utf-8')
					if ret == '':
						return None
					else:
						return json.loads(ret)
		except urlerror.HTTPError:
			raise GameAPIException('Failed to connect to API')
		except urlerror.URLError:
			raise GameAPIException('Failed to connect to API')
		except ConnectionRefusedError:
			raise GameAPIException('Connection refused')

	def save_world(self):
		"""
		Issue a Save command on the server
		:return:
		"""
		try:
			self._api_cmd('/v1/api/save', 'POST')
		except GameAPIException as e:
			print(ICON_WARNING + ' Unable to save world via game API: %s' % str(e))

	def send_message(self, message: str):
		"""
		Send a message to the game server
		:param message:
		:return:
		"""
		print('Broadcasting message: %s' % message)
		try:
			self._api_cmd('/v1/api/announce', 'POST', {'message': message})
		except GameAPIException as e:
			print(ICON_WARNING + ' Unable to send message to game API: %s' % str(e))

	def get_version(self) -> str:
		"""
		Get the game version
		:return:
		"""
		try:
			ret = self._api_cmd('/v1/api/info')
			return ret['version']
		except GameAPIException as e:
			return ICON_WARNING + ' ' + str(e)

	def get_players(self) -> Union[list, None]:
		"""
		Get the current players on the server, or None if the API is unavailable
		:return:
		"""
		try:
			ret = self._api_cmd('/v1/api/players')
			return ret['players']
		except GameAPIException:
			return None

	def get_player_count(self) -> Union[int, None]:
		"""
		Get the current number of players on the server, or None if the API is unavailable
		:return:
		"""
		try:
			ret = self._api_cmd('/v1/api/players')
			return len(ret['players'])
		except GameAPIException:
			return None

	def _is_enabled(self) -> str:
		return subprocess.run(
			['systemctl', 'is-enabled', self.name],
			stdout=subprocess.PIPE,
			stderr=subprocess.PIPE,
			check=False
		).stdout.decode().strip()

	def _is_active(self) -> str:
		"""
		Returns a string based on the status of the service:

		* active - Running
		* reloading - Running but reloading configuration
		* inactive - Stopped
		* failed - Failed to start
		* activating - Starting
		* deactivating - Stopping

		:return:
		"""
		return subprocess.run(
			['systemctl', 'is-active', self.name],
			stdout=subprocess.PIPE,
			stderr=subprocess.PIPE,
			check=False
		).stdout.decode().strip()

	def is_enabled(self) -> bool:
		"""
		Check if this service is enabled in systemd
		:return:
		"""
		return self._is_enabled() == 'enabled'

	def is_running(self) -> bool:
		"""
		Check if this service is currently running
		:return:
		"""
		return self._is_active() == 'active'

	def is_starting(self) -> bool:
		"""
		Check if this service is currently starting
		:return:
		"""
		return self._is_active() == 'activating'

	def is_stopping(self) -> bool:
		"""
		Check if this service is currently stopping
		:return:
		"""
		return self._is_active() == 'deactivating'

	def enable(self):
		"""
		Enable this service in systemd
		:return:
		"""
		subprocess.run(['systemctl', 'enable', self.name])

	def disable(self):
		"""
		Disable this service in systemd
		:return:
		"""
		subprocess.run(['systemctl', 'disable', self.name])

	def post_start(self):
		"""
		Perform necessary operations for after a game has started
		:return:
		"""
		if not self.is_running():
			print('Game is not currently running!')
			return

		try:
			if self.config.get('RESTAPIEnabled'):
				players = self.get_player_count()
				counter = 20
				while players is None and counter > 0:
					sleep(2)
					players = self.get_player_count()
					counter -= 1

				if players is not None:
					print('Verified game is online and API is connected!')
				else:
					print('Unable to verify game has started')
			else:
				sleep(30)
				print('Game should have been started, enable the API to verify.')

			wan_ip = get_wan_ip()
			port = self.config.get('PublicPort')
			passwd = self.config.get('ServerPassword')
			if wan_ip and passwd:
				discord_alert(
					'game_started',
					['%s:%s' % (wan_ip, port), 'User password: %s' % passwd]
				)
			elif wan_ip:
				discord_alert(
					'game_started',
					['%s:%s' % (wan_ip, port)]
				)
			else:
				discord_alert('game_started')
		except KeyboardInterrupt:
			print('Cancelled startup wait check')

	def start(self):
		"""
		Start this service in systemd
		:return:
		"""
		if self.is_running():
			print('Game is currently running!')
			return

		try:
			print('Starting game via systemd...')
			subprocess.run(['systemctl', 'start', self.name])
		except KeyboardInterrupt:
			print('Cancelled startup wait check, (game is probably still started)')

	def pre_stop(self) -> bool:
		"""
		Perform operations necessary for safely stopping a server

		Called automatically via systemd
		:return:
		"""
		if not (self.is_running() or self.is_stopping()):
			print('Game is not currently running!')
			return False

		try:
			discord_alert('game_stopping')
			players = self.get_player_count()
			counter = 5
			while players is not None and players > 0 and counter > 0:
				self.send_message('Server is shutting down in %s minutes, please logout.' % str(counter))
				sleep(60)
				players = self.get_player_count()
				counter -= 1

			self.save_world()
			sleep(5)
			return True
		except KeyboardInterrupt:
			self.send_message('Server shutdown cancelled')
			print('Cancelled shutdown')
			return False

	def stop(self):
		"""
		Stop this service in systemd
		:return:
		"""
		if IS_SUDO:
			print('Stopping server, please wait as players will have a 5 minute warning.')
			subprocess.run(['systemctl', 'stop', self.name])
		else:
			print('ERROR - Unable to stop game service unless run with sudo')

	def restart(self):
		"""
		Restart this service in systemd
		:return:
		"""
		if not self.is_running():
			print('Game is not currently running!')
			return

		self.stop()
		self.start()


class Table:
	"""
	Displays data in a table format
	"""

	def __init__(self, columns: Union[list, None] = None):
		"""
		Initialize the table with the columns to display
		:param columns:
		"""
		self.header = columns
		"""
		List of table headers to render, or None to omit
		"""

		self.align = []
		"""
		Alignment for each column, l = left, c = center, r = right
		
		eg: if a table has 3 columns and the first and last should be right aligned:
		table.align = ['r', 'l', 'r']
		"""

		self.data = []
		"""
		List of text data to display, add more with \`add()\`
		"""

		self.borders = True
		"""
		Set to False to disable borders ("|") around the table
		"""

	def add(self, row: list):
		self.data.append(row)

	def render(self):
		"""
		Render the table with the given list of services

		:param services: Services[]
		:return:
		"""
		rows = []
		col_lengths = []

		if self.header is not None:
			row = []
			for col in self.header:
				col_lengths.append(text_width(col))
				row.append(col)
			rows.append(row)
		else:
			col_lengths = [0] * len(self.data[0])

		for row_data in self.data:
			row = []
			for i in range(len(row_data)):
				val = str(row_data[i])
				row.append(val)
				col_lengths[i] = max(col_lengths[i], text_width(val))
			rows.append(row)

		for row in rows:
			vals = []
			for i in range(len(row)):
				if i < len(self.align):
					align = self.align[i] if self.align[i] != '' else 'l'
				else:
					align = 'l'

				# Adjust the width of the total column width by the difference of icons within the text
				# This is required because icons are 2-characters in visual width.
				width = col_lengths[i] - (text_width(row[i]) - len(row[i]))

				if align == 'r':
					vals.append(row[i].rjust(width))
				elif align == 'c':
					vals.append(row[i].center(width))
				else:
					vals.append(row[i].ljust(width))

			if self.borders:
				print('| %s |' % ' | '.join(vals))
			else:
				print('  %s' % '  '.join(vals))



def get_wan_ip() -> Union[str, None]:
	"""
	Get the external IP address of this server
	:return:
	"""
	try:
		with request.urlopen('https://api.ipify.org') as resp:
			return resp.read().decode('utf-8')
	except urlerror.HTTPError:
		return None
	except urlerror.URLError:
		return None


def load_config() -> configparser.ConfigParser:
	config = configparser.ConfigParser()
	config.read(os.path.join(here, '.settings.ini'))
	if 'Discord' not in config.sections():
		config['Discord'] = {}
	return config


def save_config(config: configparser.ConfigParser):
	"""
	Save the management application configuration to disk
	:return:
	"""
	with open(os.path.join(here, '.settings.ini'), 'w') as f:
		config.write(f)
	os.chmod(os.path.join(here, '.settings.ini'), 0o600)
	if IS_SUDO:
		subprocess.run(['chown', 'steam:steam', os.path.join(here, '.settings.ini')])


def header(line):
	"""
	Print a header line
	:param line: string
	:return:
	"""
	#os.system('clear')
	# Instead of clearing the screen, just print some newlines.
	# This way errors from the previous screen will be visible.
	print('')
	print('')
	print('')
	print('')
	print('== %s ==' % line)
	print('')


def menu_watch():
	"""
	Interface responsible for watching the server for activity

	Shutdown operations are handled with pre_stop from within systemd, so this only handles startup
	and player actions.
	:return:
	"""
	running = False
	players = []
	player_levels = {}
	while True:
		sleep(30)
		game = GameService()
		if game.is_running():
			if not running:
				# Game was not running, but now is.
				game.post_start()
				running = True

			# Game is running, check for players
			current_player_data = game.get_players()
			current_players = []
			if current_player_data is not None:
				for player in current_player_data:
					current_players.append(player['name'])

					if player['name'] not in players:
						players.append(player['name'])
						discord_alert('player_joined', [player['name']])
						player_levels[player['name']] = player['level']

					if player_levels[player['name']] != player['level']:
						discord_alert('player_leveled_up', [player['name'], player['level']])
						player_levels[player['name']] = player['level']

				for player in players:
					if player not in current_players:
						discord_alert('player_left', [player])
						players.remove(player)
						del player_levels[player]
		else:
			running = False
			players = []
			player_levels = {}


def menu_admin_password(game: GameService):
	"""
	Interface to manage rcon and administration password
	:return:
	"""
	while True:
		header('Admin and RCON Configuration')
		table = Table()
		table.borders = False
		table.align = ['r', 'r', 'l', 'l']
		table.add([
			'Admin Password:',
			'(opt 1)',
			game.config.get('AdminPassword'),
			'Password for connecting to RCON or the REST API'
		])
		table.add([
			'RCON Status:',
			'(opt 2)',
			ICON_ENABLED + ' Enabled' if game.config.get('RCONEnabled') else ICON_DISABLED + ' Disabled',
			'Enable to allow remote control of the server'
		])
		table.add([
			'RCON Port:',
			'(opt 3)',
			game.config.get('RCONPort'),
			'Port for RCON connections'
		])
		table.add([
			'REST Status:',
			'(opt 4)',
			ICON_ENABLED + ' Enabled' if game.config.get('RESTAPIEnabled') else ICON_DISABLED + ' Disabled',
			'Enable to allow remote control of the server'
		])
		table.add([
			'REST Port:',
			'(opt 5)',
			game.config.get('RESTAPIPort'),
			'Port for REST API connections'
		])
		table.render()
		print('')
		opt = input('Enter option 1-5 or [B]ack: ').lower()

		if opt == 'b':
			return

		elif opt == '1':
			val = input('Enter new password: ').strip()
			if val:
				game.config.set('AdminPassword', 'string', val)
				game.config.save()

		elif opt == '2':
			game.config.set('RCONEnabled', 'bool', not game.config.get('RCONEnabled'))
			game.config.save()

			# RCON is generally meant to be access remotely.
			if game.config.get('RCONENabled'):
				ufw_enable(game.config.get('RCONPort'), 'tcp', 'Allow Palworld RCON from anywhere')
			else:
				ufw_disable(game.config.get('RCONPort'), 'tcp')

		elif opt == '3':
			prev_port = game.config.get('RCONPort')
			val = rl_input('Enter new RCON port: ', str(prev_port)).strip()
			if val:
				game.config.set('RCONPort', 'int', int(val))
				game.config.save()

				# RCON is generally meant to be access remotely.
				if game.config.get('RCONENabled'):
					ufw_disable(prev_port, 'tcp')
					ufw_enable(game.config.get('RCONPort'), 'tcp', 'Allow Palworld RCON from anywhere')

		elif opt == '4':
			game.config.set('RESTAPIEnabled', 'bool', not game.config.get('RESTAPIEnabled'))
			game.config.save()

		elif opt == '5':
			val = rl_input('Enter new REST API port: ', str(game.config.get('RESTAPIPort'))).strip()
			if val:
				game.config.set('RESTAPIPort', 'int', int(val))
				game.config.save()

		else:
			print('Invalid option')


def menu_discord():
	config = load_config()

	while True:
		header('Discord Integration')
		enabled = config['Discord'].get('enabled', '0') == '1'
		webhook = config['Discord'].get('webhook', '')
		if webhook == '':
			print('Discord has not been integrated yet.')
			print('')
			print('If you would like to send shutdown / startup notifications to Discord, you can')
			print('do so by adding a Webhook (Discord -> Settings -> Integrations -> Webhooks -> Create Webhook)')
			print('and pasting the generated URL here.')
			print('')
			print('URL or just the character "b" to go [B]ack.')
			opt = input(': ')

			if 'https://' in opt:
				config['Discord']['webhook'] = opt
				config['Discord']['enabled'] = '1'
				save_config(config)
			else:
				return
		else:
			discord_channel = None
			discord_guild = None
			discord_name = None
			req = request.Request(webhook, headers={'Accept': 'application/json', 'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:135.0) Gecko/20100101 Firefox/135.0'}, method='GET')
			try:
				with request.urlopen(req) as resp:
					data = json.loads(resp.read().decode('utf-8'))
					discord_channel = data['channel_id']
					discord_guild = data['guild_id']
					discord_name = data['name']
			except urlerror.HTTPError as e:
				print('Error: %s' % e)
			except json.JSONDecodeError as e:
				print('Error: %s' % e)

			if enabled and discord_name:
				print('Discord integration is currently available and enabled!')
			elif discord_name:
				print('Discord integration is currently DISABLED.')
			else:
				print('Discord integration is currently unavailable, bad Webhook URL?')
			print('')
			print('Discord Webhook URL:  %s' % webhook[0:webhook.rindex('/')+5] + '************' + webhook[-4:])
			print('Discord Channel ID:   %s' % discord_channel)
			print('Discord Guild ID:     %s' % discord_guild)
			print('Discord Webhook Name: %s' % discord_name)
			print('')

			options = []
			if enabled:
				options.append('[D]isable')
			else:
				options.append('[E]nable')

			options.append('[C]hange Discord webhook URL')
			options.append('configure [M]essages')
			options.append('[B]ack')
			print(' | '.join(options))
			opt = input(': ').lower()

			if opt == 'b':
				return
			elif opt == 'm':
				menu_discord_messages()
			elif opt == 'c':
				print('do so by adding a Webhook (Discord -> Settings -> Integrations -> Webhooks -> Create Webhook)')
				print('and pasting the generated URL here.')
				val = input('Enter new Discord webhook URL: ').strip()
				if val != '':
					config['Discord']['webhook'] = val
					save_config(config)
			elif opt == 'e':
				config['Discord']['enabled'] = '1'
				save_config(config)
			elif opt == 'd':
				config['Discord']['enabled'] = '0'
				save_config(config)
			else:
				print('Invalid option')


def menu_discord_messages():
	while True:
		header('Discord Messages')
		print('The following messages will be sent to Discord when certain events occur.')
		table = Table()
		table.borders = False
		options = {
			'game_started': 'Game Started',
			'game_stopping': 'Game Stopping',
			'player_joined': 'Player Joined',
			'player_left': 'Player Left',
			'player_leveled_up': 'Player Leveled Up'
		}
		opts = ['']
		counter = 0
		for key, val in options.items():
			counter += 1
			table.add([val, '(opt %s)' % counter, discord_message(key)])
			opts.append(key)
		table.render()
		print('')
		opt = input('[1-%s] change message | [B]ack: ' % str(len(opts) - 1)).lower()
		key = None
		val = ''

		if opt == 'b':
			return
		elif 1 <= int(opt) < len(opts):
			key = opts[int(opt)]
			print('')
			print('Edit the message, left/right works to move cursor.  Blank to use default.')
			val = rl_input('%s: ' % options[key], discord_message(key)).strip()
		else:
			print('Invalid option')

		if key is not None:
			config = load_config()
			config['Discord'][key] = val.replace('%', '%%')
			save_config(config)


def menu_crossplay(game: GameService):
	opts = game.config.get('CrossplayPlatforms', [])

	while True:
		header('Crossplay Configuration')

		table = Table()
		table.borders = False
		table.add([
			'(opt 1)',
			ICON_ENABLED + ' Steam' if 'Steam' in opts else ICON_DISABLED + ' Steam',
		])
		table.add([
			'(opt 2)',
			ICON_ENABLED + ' Xbox' if 'Xbox' in opts else ICON_DISABLED + ' Xbox',
		])
		table.add([
			'(opt 3)',
			ICON_ENABLED + ' PS5' if 'PS5' in opts else ICON_DISABLED + ' PS5',
		])
		table.add([
			'(opt 4)',
			ICON_ENABLED + ' Mac' if 'Mac' in opts else ICON_DISABLED + ' Mac',
		])

		table.render()
		print('')
		opt = input('1-4 to toggle platform | [S]ave changes | [C]ancel changes: ').lower()

		if opt == 'c':
			return

		elif opt == 's':
			game.config.set('CrossplayPlatforms', 'group', opts)
			game.config.save()
			return

		elif opt == '1':
			if 'Steam' in opts:
				opts.remove('Steam')
			else:
				opts.append('Steam')

		elif opt == '2':
			if 'Xbox' in opts:
				opts.remove('Xbox')
			else:
				opts.append('Xbox')

		elif opt == '3':
			if 'PS5' in opts:
				opts.remove('PS5')
			else:
				opts.append('PS5')

		elif opt == '4':
			if 'Mac' in opts:
				opts.remove('Mac')
			else:
				opts.append('Mac')

		else:
			print('Invalid option')


def menu_first_run(game: GameService):
	header('First Run Configuration')

	if yn_input('Enable API integration? (recommended)', 'y'):
		chars = 'abcdefghjkpqrstwxyzACDEFGHJKPRTWXYZ234679'
		game.config.set('RESTAPIEnabled', 'bool', True)
		game.config.set('AdminPassword', 'string', ''.join(random.choices(chars, k=16)))

	opt = rl_input('Enter the server name: ', game.config.get('ServerName', '')).strip()
	game.config.set('ServerName', 'string', opt)

	opt = rl_input('Enter the server description: ', game.config.get('ServerDescription', '')).strip()
	game.config.set('ServerDescription', 'string', opt)

	if yn_input('Require a password for players to join?', 'n'):
		opt = rl_input('Enter the password: ', game.config.get('ServerPassword', '')).strip()
		game.config.set('ServerPassword', 'string', opt)


def menu_main(game: GameService):
	stay = True
	wan_ip = get_wan_ip()

	while stay:
		header('Welcome to the Palworld Linux Server Manager')
		print('Found an issue? https://github.com/VeraciousNetwork/Palworld-Linux/issues')
		print('Want to help financially support this project? https://ko-fi.com/Q5Q013RM9Q')
		print('')
		table = Table()
		table.borders = False
		table.align = ['r', 'r', 'l']
		table.add([
			'Server Name:',
			'(opt 1)',
			game.config.get('ServerName')
		])
		table.add([
			'Port:',
			'(opt 2)',
			game.config.get('PublicPort')
		])
		table.add([
			'Direct Connect:',
			'',
			'%s:%s' % (wan_ip, game.config.get('PublicPort')) if wan_ip else 'N/A'
		])
		table.add([
			'Player Password:',
			'(opt 3)',
			game.config.get('ServerPassword')
		])
		table.add([
			'Crossplay:',
			'(opt 4)',
			', '.join(game.config.get('CrossplayPlatforms', []))
		])
		table.add([
			'Status:',
			'',
			ICON_ENABLED + ' Running' if game.is_running() else ICON_STOPPED + ' Stopped'
		])
		table.add([
			'Auto-Start:',
			'(opt 5)' if IS_SUDO else '----',
			ICON_ENABLED + ' Enabled' if game.is_enabled() else ICON_DISABLED + ' Disabled'
		])
		table.add([
			'Version:',
			'',
			game.get_version()
		])
		table.add([
			'Players Online:',
			'',
			game.get_player_count()
		])
		table.render()

		print('')
		print('Configure: [A]dmin password/API/RCON | [D]iscord')
		if IS_SUDO:
			if game.is_running():
				print('Control: s[T]op | [R]estart')
			else:
				print('Control: [S]tart | [U]pdate')
		elif not game.is_running():
			print('Control: [U]pdate')
		print('or [Q]uit to exit')
		opt = input(': ').lower()

		if opt == 'q':
			stay = False

		elif opt == 'a':
			menu_admin_password(game)

		elif opt == 'd':
			menu_discord()

		elif opt == 's':
			game.start()

		elif opt == 't':
			game.stop()

		elif opt == 'u':
			subprocess.run([os.path.join(here, 'update.sh')], stdout=sys.stdout, stderr=sys.stderr, check=False)

		elif opt == '1':
			opt = rl_input('Enter the server name: ', game.config.get('ServerName', '')).strip()
			game.config.set('ServerName', 'string', opt)
			game.config.save()

		elif opt == '2':
			prev_port = game.config.get('PublicPort')
			opt = rl_input('Enter the server port: ', str(prev_port)).strip()
			if opt != '':
				game.config.set('PublicPort', 'int', int(opt))
				game.config.save()

				ufw_disable(prev_port, 'udp')
				ufw_enable(game.config.get('PublicPort'), 'udp', 'Allow Palworld from anywhere')

		elif opt == '3':
			opt = rl_input('Enter the server password: ', game.config.get('ServerPassword', '')).strip()
			game.config.set('ServerPassword', 'string', opt)
			game.config.save()

		elif opt == '4':
			menu_crossplay(game)

		elif opt == '5':
			if game.is_enabled():
				game.disable()
			else:
				game.enable()

parser = argparse.ArgumentParser('manage.py')
parser.add_argument(
	'--pre-stop',
	help='Send notifications to game players and Discord and save the world',
	action='store_true'
)
parser.add_argument(
	'--watch',
	help='Send notifications to game players and Discord and save the world',
	action='store_true'
)
args = parser.parse_args()

if args.pre_stop:
	GameService().pre_stop()
elif args.watch:
	menu_watch()
else:
	g = GameService()
	if not GameService().config.configured:
		menu_first_run(g)

	menu_main(g)
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
[Unit]
# DYNAMICALLY GENERATED FILE! Edit at your own risk
Description=Palworld Dedicated Server Watcher
After=network.target

[Service]
Type=simple
LimitNOFILE=10000
User=$GAME_USER
Group=$GAME_USER
WorkingDirectory=$GAME_DIR/AppFiles
Environment=XDG_RUNTIME_DIR=/run/user/$(id -u $GAME_USER)
ExecStart=$GAME_DIR/manage.py --watch
Restart=on-failure
RestartSec=20s

[Install]
WantedBy=multi-user.target
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
