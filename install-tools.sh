#!/bin/bash

set -euo pipefail

# Install my common tools.
#
# Note that this script makes no attempt to update any corresponding dotfiles.
# When adding new applications to be installed to this script, you should also
# update that appropriate dotfiles at the same time (and commit those changes
# alongside the changes to this file).  Note also that you should run the
# setup-dotfiles.sh script before running this script so that all of the necessary
# dotfiles are in place.
#

declare -r DATA_VOLUME="/d"

function main () {

    # Get OS info (version, code name, etc)
    source /etc/os-release

    # Make sure we're up to date before we start installing stuff
    sudo apt update
    sudo apt upgrade

    installCommonTools
    installJqYq
    installDocker
    installKubectl
    installK9s
    installHelm
    installAwsCli
    installTerraformAndPacker
    sudo apt install shellcheck

    sudo apt install -yf openjdk-11-jdk
    installKeystoreExplorer

    installSublimeText
    installChrome


}

function installCommonTools() {

  # Install some common packages
  sudo apt install -y \
    ca-certificates \
    curl \
    gnupg \
    software-properties-common \
    tree \
    make \
    zstd

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
  sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
  sudo apt install -y uidmap

  # Let user run docker without sudo
  #sudo groupadd docker
  sudo usermod -aG docker "$USER"

  # Use default docker configuraiton unless we detect a second volume 
  # mounted at /d
  if [ -d "$DATA_VOLUME" ]; then
    sudo tee "/etc/docker/daemon.json" > /dev/null << EOF
{
  "data-root": "${DATA_VOLUME}/docker",
  "default-address-pools": [
    {"base":"172.16.0.0/13","size":20}
  ]
}
EOF
  fi

}

function installKubectl() {

  # From https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-using-native-package-management

  curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key \
     | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
  # allow unprivileged APT programs to read this keyring
  sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg

  echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | \
    sudo tee /etc/apt/sources.list.d/kubernetes.list
  # helps tools such as command-not-found to work correctly
  sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list

  sudo apt-get update
  sudo apt-get install -y kubectl

  # kubectl tab completion
  # https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#enable-shell-autocompletion
  kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null
  sudo chmod a+r /etc/bash_completion.d/kubectl

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

function installK9s() {
# From https://github.com/derailed/k9s?tab=readme-ov-file#installation

  wget -P /tmp https://github.com/derailed/k9s/releases/download/v0.32.7/k9s_linux_amd64.deb
  sudo apt install /tmp/k9s_linux_amd64.deb

}

function installHelm() {
  # From https://helm.sh/docs/intro/install/#from-apt-debianubuntu

  curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
  sudo apt-get install apt-transport-https --yes
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | \
    sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
  sudo apt-get update
  sudo apt-get install helm
}

function installAwsCli {

  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
  unzip /tmp/awscliv2.zip -d /tmp
  sudo /tmp/aws/install --update

}

function installTerraformAndPacker() {
  wget -O- https://apt.releases.hashicorp.com/gpg | \
    gpg --dearmor | \
    sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
    https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
    sudo tee /etc/apt/sources.list.d/hashicorp.list

  sudo apt update

  sudo apt install terraform packer

  # terraform and packer autocomplete are so basic and incomplete that I'm not
  # they're worth even installing since the break bash tab completion on the
  # rest of the line container a packer or terraform command
  # terraform -install-autocomplete
  # packer -autocomplete-install

  # TODO: Terraform wont create the plugin cache directory if it doesnt exist
  # The plugin-cache directory normally lives under .terraform.d in the home
  # directory, so it could be viewed as a dotfile, but it's not one that's
  # tracked with the rest of our dotfiles and our dotfile setup doesnt
  # support empty directory placeholders.  So do we just create that directory
  # here, even though it might never be used? Yes?
  mkdir -p "$HOME/terraform.d/plugin-cache"
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

function installChrome {
  wget -qP /tmp/ https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
  sudo dpkg -i /tmp/google-chrome-stable_current_amd64.deb
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
