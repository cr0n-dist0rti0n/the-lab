#!/bin/bash

# ANSI escape codes for text formatting
YELLOW='\033[1;33m'
RESET='\033[0m'

# Initiate sudo
if [ "$EUID" -ne 0 ]; then
  echo ""
  echo "Please run this script with sudo:"
  echo ""
  echo -e "${YELLOW}sudo $0 $*${RESET}"
  echo ""
  exit 1
fi

echo ""
echo -e "${YELLOW}Enter ATOR Relay's External IP Address: ${RESET}"
echo ""
read ip_address

# Update Debian OS and Install nyx
apt-get update -y
apt-get upgrade -y
apt-get install nyx -y

# Add Docker's official GPG key:
apt-get install ca-certificates curl gnupg -y
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update

# Get files and prep directory
mkdir /opt/compose-files/
wget -O /opt/compose-files/ator.yaml https://raw.githubusercontent.com/rA3ka/the-lab/main/docker/ator-relay/ator.yaml
mkdir -p /opt/ator/etc/tor/
wget -O /opt/ator/etc/tor/torrc https://raw.githubusercontent.com/rA3ka/the-lab/main/docker/ator-relay/torrc
touch /opt/ator/etc/tor/notices.log
chown 100:101 /opt/ator/etc/tor/notices.log
mkdir -p /opt/ator/run/tor/
chown -R 100:101 /opt/ator/run/tor/
chmod -R 700 /opt/ator/run/tor/
mkdir -p /root/.nyx/
wget -O /root/.nyx/config https://raw.githubusercontent.com/rA3ka/the-lab/main/docker/ator-relay/config
useradd -M atord

# Install ATOR Docker 
docker compose -f /opt/compose-files/ator.yaml up -d
echo ""
echo "~~~~~~~~~~~~~ ATOR Relay ~~~~~~~~~~~~~"
echo ""
docker ps
echo ""
echo "~~~~~~~~~~~~~ Installing IP ~~~~~~~~~~~~~"
echo ""
echo "Address ${ip_address}" | docker exec -i ator-relay sh -c 'cat >> /etc/tor/torrc'
echo ""
echo "${YELLOW}Would you like to start nyx? (y/n)${RESET}"
read nyx_load

if [ "$nyx_load" == "y" ] || [ "$nyx_load" == "Y" ]; then
  echo ""
  echo "${YELLOW}OK. Running 'nyx -s /opt/ator/run/tor/control'...${RESET}"
  nyx -s /opt/ator/run/tor/control
else
  echo ""
  echo "${YELLOW}OK. Exiting Now.${RESET}"
  exit 1
fi

exit 1