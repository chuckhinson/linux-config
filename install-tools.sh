#!/bin/bash

set -euo pipefail

function main () {

    # Get OS info (version, code name, etc)
    source /etc/os-release

    # Make sure we're up to date before we start installing stuff
    sudo apt update
    sudo apt upgrade

    installCommonPackages
    installSublimeText
    installShellcheck
    installChrome
    installJava
    installKeystoreExplorer    
}

function installCommonPackages() {

  # Install some common packages
  sudo apt install -y \
    ca-certificates \
    curl \
    net-tools \
    software-properties-common
  
  # (Re)install vim.  The version of vim included with the ubuntu ISO seems not to work 
  # quite right for me.  Not a vim expert, so this might be the wrong way to solve the
  # problem, but it works for me.  (Note that this doesnt appear to a problem with 
  # AWS Ubuntu AMIs, so doing this on an EC2 instance isnt necessary, but doesnt hurt 
  # anything)
  sudo apt install -y vim

}

function installSublimeText() {

  wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | \
   gpg --dearmor | \
   sudo tee /etc/apt/trusted.gpg.d/sublimehq-archive.gpg > /dev/null

  echo "deb https://download.sublimetext.com/ apt/stable/" | \
   sudo tee /etc/apt/sources.list.d/sublime-text.list

  sudo apt-get update
  sudo apt-get install sublime-text

#  cp -R --no-clobber ~/.config/sublime-text/Packages/User/ sublime-test-3/User
#  mv ~/.config/sublime-text/Packages/User ~/.config/sublime-text/Packages/User.orig
  mkdir -p ~/.config/sublime-text/Packages
  ln -s ~/linux-config/sublime-text-3/Packages/User ~/.config/sublime-text/Packages/User

  installSublimePackageControl

}

function installSublimePackageControl() {
  # Lifted from https://github.com/drliangjin/sublime.d

  PACKAGE_URL="https://packagecontrol.io/Package%20Control.sublime-package"
  PACKAGE_DIR_UBUNTU="$HOME/.config/sublime-text/Installed Packages"
  PACKAGE_FILE="Package Control.sublime-package"
  PACKAGE_NAME="Package Control"

  local package=${PACKAGE_DIR_UBUNTU}/${PACKAGE_FILE}
  if [[ ! -f "${package}" ]]; then
    echo " => installing ${PACKAGE_NAME}..."
    mkdir -p "${PACKAGE_DIR_UBUNTU}"
    wget -q "${PACKAGE_URL}" -O "${package}"
    if [[ $? != 0 ]]; then
      echo " => unable to download ${PACKAGE_NAME}!"
      exit 1
    fi
    echo " => installing ${PACKAGE_NAME}...done"
  else
    echo "${PACKAGE_NAME} already exists..."
  fi  

}

function installShellcheck {

  sudo apt install shellcheck

}

function installChrome {
  wget -qP /tmp/ https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
  sudo dpkg -i /tmp/google-chrome-stable_current_amd64.deb
}

function installJava () {

    sudo apt install -yf openjdk-11-jdk

}

function installKeystoreExplorer () {
  # NOTE: has dependency on java but does not install it

  local KS_VERSION="5.5.1"
  local KS_FILE="kse_${KS_VERSION}_all.deb"
  local KS_URI="https://github.com/kaikramer/keystore-explorer/releases/download/v${KS_VERSION}/${KS_FILE}"

  wget -P /tmp/ "${KS_URI}"
  sudo dpkg -i "/tmp/${KS_FILE}"

}

main "$@"
