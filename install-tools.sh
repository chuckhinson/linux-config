#!/bin/bash

# Install my common tools.
#
# Note that this script makes no attempt to update any corresponding dotfiles.
# When adding new applications to be installed to this script, you should also
# update that appropriate dotfiles at the same time (and commit those changes
# alongside the changes to this file).  Note also that you should run the
# setup-links.sh script before running this script so that all of the necessary
# dotfiles are in place.
#

set -euo pipefail

function main () {

    # Get OS info (version, code name, etc)
    source /etc/os-release

    # Make sure we're up to date before we start installing stuff
    sudo apt update
    sudo apt upgrade

    installCommonPackages
    installJqYq
    installDocker
    installKubectl
    installSublimeText
    installShellcheck
    installChrome
    installJava
    installKeystoreExplorer
    installAwsCli    
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

function installJqYq () {

  # jq and yq are json and yaml parsing tools - kind of like xquery
  # for json and yaml.
  # Note that while yaml is supposedly a superset of json and thus
  # yq should be able to parse json as well as yaml, as of this
  # writing, yq does not have all of the features that jq has, so
  # we're installing jq and yq for now.

  sudo apt install -y jq

  local YQ_VERSION="4.30.6"
  local YQ_URI="https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64"
  sudo wget "${YQ_URI}" -O /usr/bin/yq
  sudo chmod +x /usr/bin/yq

}


function installDocker() {

  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  sudo apt update -q
  sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin

  # Let user run docker without sudo
  #sudo groupadd docker
  sudo usermod -aG docker "$USER"

  # Use default docker configuraiton unless we detect a second volume 
  # mounted at /d
  if [ -d /d ]; then
    sudo tee "/etc/docker/daemon.json" > /dev/null << EOF
{
  "data-root": "/d/docker",
  "default-address-pools": [
    {"base":"172.16.0.0/13","size":20}
  ]
}
EOF
  fi

}

function installKubectl() {

  sudo curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg \
   https://packages.cloud.google.com/apt/doc/apt-key.gpg

  echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] \
    https://apt.kubernetes.io/ kubernetes-xenial main" | \
    sudo tee /etc/apt/sources.list.d/kubernetes.list

  sudo apt-get update
  sudo apt-get install -y kubectl

  # kubectl tab completion
  # https://kubernetes.io/docs/tasks/tools/included/optional-kubectl-configs-bash-linux/
  kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null


  # krew kubectl plugin manager
  # https://krew.sigs.k8s.io/docs/user-guide/setup/install/
  OS="$(uname | tr '[:upper:]' '[:lower:]')"
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')"
  KREW="krew-${OS}_${ARCH}"

  curl -fsSL -o "/tmp/${KREW}.tar.gz" "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" \

  tar -C /tmp -zxvf "/tmp/${KREW}.tar.gz"

  /tmp/"${KREW}" install krew

  # Note: krew needs $HOME/.krew/bin to be on your PATH
  export PATH="$HOME/.krew/bin:$PATH"
  kubectl krew install ctx ns

}

function installSublimeText() {

  wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | \
   gpg --dearmor | \
   sudo tee /etc/apt/trusted.gpg.d/sublimehq-archive.gpg > /dev/null

  echo "deb https://download.sublimetext.com/ apt/stable/" | \
   sudo tee /etc/apt/sources.list.d/sublime-text.list

  sudo apt-get update
  sudo apt-get install sublime-text

  # User preferences dont get setup until the first time Sublime is run, so we can
  # just drop our stuff where it should go and then Sublime can reference it and add
  # to it once it runs the first time.
  # TODO: preserve the original Packages/User directory before linking it
  #  cp -R --no-clobber ~/.config/sublime-text/Packages/User/ sublime-test-3/User
  #  mv ~/.config/sublime-text/Packages/User ~/.config/sublime-text/Packages/User.orig

  mkdir -p ~/.config/sublime-text/Packages
  ln -s ~/linux-config/sublime-text-3/Packages/User ~/.config/sublime-text/Packages/User

  installSublimePackageControl

}

function installSublimePackageControl() {
  # Lifted from https://github.com/drliangjin/sublime.d
  # Note that an alternative method is to use sublime's CLI interface
  # e.g., subl --command install_package_control, although it is somewhat
  # finicky and requires multiple invocations (like sublime has to already
  # be running before executing the install_package_control command and then
  # you have to sleep for a bit to give it time to complete)
  # See https://forum.sublimetext.com/t/installing-packages-from-the-command-line/64029/4
  # and https://www.sublimetext.com/docs/command_line.html

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

function installAwsCli {
  
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-2.0.30.zip" -o "/tmp/awscliv2.zip"
  unzip /tmp/awscliv2.zip -d /tmp
  sudo /tmp/aws/install

}


main "$@"
