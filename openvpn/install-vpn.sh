#!/bin/bash

set -euo pipefail

OPENVPN_DIR="${HOME}/.openvpn"

function installOpenvpn () {

  if [[ $(dpkg -l openvpn3) ]]; then
    echo "OpenVPN3 is already installed"
  else
    echo "OpenVPN3 not found. Installing OpenVPN3..."

    if [[ ! $(grep -qr openvpn3 /etc/apt/sources.list*) ]]; then
      echo "Adding OpenVPN repository"
      sudo wget -qO - https://swupdate.openvpn.net/repos/openvpn-repo-pkg-key.pub | sudo apt-key add -
      sudo wget -O /etc/apt/sources.list.d/openvpn3.list "https://swupdate.openvpn.net/community/openvpn3/repos/openvpn3-$UBUNTU_CODENAME.list"
      sudo apt update 
    fi
	  
  	  sudo apt install -y openvpn3
      printf "\nInstalled OpenVpn3 %s \n" "$(dpkg -l openvpn3)"
  fi

}


function configureOpenVpn () {
  # TODO: make this symlink to linux-config
  mkdir -p "${OPENVPN_DIR}"
  cp "${HOME}/client.ovpn" "${OPENVPN_DIR}/"

  # when we connect to VPN, we need to tell openvpn to reconfigure our DNS server 
  # to use the DNS server for the VPN environment otherwise DNS wont work for any
  # of the hosts that are on the private network.
  cat >> "${OPENVPN_DIR}/client.ovpn" << EOF
script-security 2
up ${OPENVPN_DIR}/bin/update-resolv-conf
down ${OPENVPN_DIR}/bin/update-resolv-conf
EOF

  # Setup a named configuration profile that we can reference when we
  # start up vpn
  openvpn3 config-import -c "${OPENVPN_DIR}/client.ovpn" --name default -p

  printf "OpenVpn configuration complete\n"

}


function installBins () {

  # install net-tools to make route command available for start/stop scripts
  sudo apt install net-tools

  cp -r ./bin "${OPENVPN_DIR}/bin"

  # TODO: fix this so it wont add multiple entries if run more than once.
  cat >> ~/.bashrc << EOF
export PATH=${OPENVPN_DIR}/bin:\$PATH
EOF

}

function main () {

  source /etc/os-release

  if [ -f "${HOME}/client.ovpn" ]; then
    installOpenvpn
    configureOpenVpn
    installBins
  else
  	printf "Cannot find ${HOME}/client.ovpn. \n"
  	printf "Download your profile and save as ${HOME}/client.ovpn"
    exit 1
  fi

}


main "$@"
