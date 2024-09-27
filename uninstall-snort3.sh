# This script uninstalls Snort 3 and its related packages from a system.
# It performs the following steps:
# 1. Defines text formatting for log messages.
# 2. Defines logging functions with timestamp and different log levels (INFO, WARNING, ERROR, SUCCESS).
# 3. Uninstalls Snort 3 and related packages (snort3, libdaq, libdnet, luajit, pcre, hwloc, zlib).
# 4. Handles special case for 'flex' package due to dependencies.
# 5. Stops and disables the Snort service if it exists.
# 6. Removes the Snort service file if it exists.
# 7. Reloads systemd services.
# 8. Removes the Snort user and group if they exist.
# 9. Removes the Snort log directory if it exists.
# 10. Revokes privileges from the Snort binary and removes it if it exists.
# 11. Removes Snort configuration files if they exist.
# 12. Disables promiscuous mode on the main network interface.
# 13. Cleans up temporary files related to Snort.
# 14. Logs a success message upon completion.
#!/bin/bash

# Définition du formatage du texte
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
BOLD='\033[1m'
NORMAL='\033[0m'

# Fonction de journalisation avec horodatage
log() {
    local LEVEL="$1"
    shift
    local MESSAGE="$*"
    local TIMESTAMP
    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    echo -e "${TIMESTAMP} ${LEVEL} ${MESSAGE}"
}

# Fonctions de journalisation
info_message() {
    log "${BLUE}${BOLD}[INFO]${NORMAL}" "$*"
}

warn_message() {
    log "${YELLOW}${BOLD}[WARNING]${NORMAL}" "$*"
}

error_message() {
    log "${RED}${BOLD}[ERROR]${NORMAL}" "$*"
}

success_message() {
    log "${GREEN}${BOLD}[SUCCESS]${NORMAL}" "$*"
}

print_step() {
    log "${BLUE}${BOLD}[STEP]${NORMAL}" "$1: $2"
}

# Désinstallation de Snort et des dépendances
print_step "Uninstalling" "Snort and related packages..."

PACKAGES=(
    "snort3"
    "libdaq"
    "libdnet"
    "luajit"
    "pcre"
    "hwloc"
    "zlib"
)

for package in "${PACKAGES[@]}"; do
    if dpkg -l | grep -q "^ii\s\+$package"; then
        print_step "Removing" "$package..."
        if ! sudo apt-get remove --purge -y "$package"; then
            warn_message "Failed to remove $package due to dependency issues."
        fi
    else
        warn_message "$package is not installed, skipping..."
    fi
done

# Gestion spéciale pour 'flex' en raison des dépendances
if dpkg -l | grep -q "^ii\s\+flex"; then
    print_step "Removing" "flex..."
    if dpkg -l | grep -q "^ii\s\+libfl-dev"; then
        print_step "Also removing" "libfl-dev which depends on flex..."
        sudo apt-get remove --purge -y libfl-dev flex
    else
        sudo apt-get remove --purge -y flex
    fi
else
    warn_message "flex is not installed, skipping..."
fi

# Arrêt et désactivation du service Snort avant de supprimer l'utilisateur
print_step "Stopping and disabling" "Snort service..."
if systemctl list-units --full -all | grep -Fq 'snort.service'; then
    sudo systemctl stop snort.service
    sudo systemctl disable snort.service
else
    warn_message "Snort service does not exist, skipping..."
fi

# Suppression du fichier de service Snort
print_step "Removing" "Snort service file..."
if [ -f /etc/systemd/system/snort.service ]; then
    sudo rm -f /etc/systemd/system/snort.service
else
    warn_message "Snort service file does not exist, skipping..."
fi

# Rechargement des services systemd
print_step "Reloading" "systemd services..."
sudo systemctl daemon-reload

# Suppression de l'utilisateur et du groupe Snort
print_step "Removing" "Snort user and group..."
if id "snort" &>/dev/null; then
    if pgrep -u snort > /dev/null; then
        print_step "Terminating" "processes running under 'snort' user..."
        sudo pkill -u snort
    fi
    sudo userdel -r snort
else
    warn_message "Snort user does not exist, skipping..."
fi

if getent group snort &>/dev/null; then
    sudo groupdel snort
else
    warn_message "Snort group does not exist, skipping..."
fi

# Suppression du répertoire de logs Snort
print_step "Removing" "Snort log directory..."
if [ -d /var/log/snort ]; then
    sudo rm -rf /var/log/snort
else
    warn_message "Snort log directory does not exist, skipping..."
fi

# Révocation des privilèges du binaire Snort avant suppression
print_step "Revoking privileges" "from Snort binary..."
if [ -f /usr/local/bin/snort ]; then
    sudo setcap -r /usr/local/bin/snort
    sudo rm -f /usr/local/bin/snort
else
    warn_message "Snort binary does not exist, skipping..."
fi

# Suppression des fichiers de configuration Snort
print_step "Removing" "Snort configuration files..."
if [ -d /usr/local/etc/snort ]; then
    sudo rm -rf /usr/local/etc/snort
else
    warn_message "Snort configuration directory does not exist, skipping..."
fi

# Désactivation du mode promiscuité sur l'interface réseau principale
print_step "Disabling" "promiscuous mode on the network interface..."
MAIN_INTERFACE=$(ip route | grep default | awk '{print $5}')
if [[ -n "$MAIN_INTERFACE" ]]; then
    sudo ip link set "$MAIN_INTERFACE" promisc off
else
    warn_message "Unable to determine the main network interface, skipping promiscuous mode reset."
fi

# Nettoyage des fichiers temporaires
print_step "Cleaning up" "temporary files..."
sudo rm -rf /tmp/snort-*

success_message "Snort and all related packages uninstalled and changes reverted successfully."
