#!/usr/bin/env bash

set -e

log() {
  GREEN='\033[0;32m'
  NC='\033[0m'
  printf "%b%s%b\n" "$GREEN" "$1" "$NC"
}

ensureWinExeSymlink() {
  mkdir -p $(dirname "$2")
  winExePath=$(command -v $1 || true)
  if [ -f "$winExePath" ] ; then
    log "symlinking $winExePath to $2"
    rm -f "$2" && ln -s "$winExePath" "$2"
  else
    log "did not create symlink for $1 because it does not exist"
  fi
}

is_wsl() {
  [ -n "${WSL_DISTRO_NAME+isset}" ]
}

install_gitconfig() {
  log "installing gitconfig"
  cp ./gitconfig/.gitconfig ~/
}

install_pwsh_profile() {
  log "installing pwsh profile"
  mkdir -p ~/.config/powershell/
  cp ./pwsh-profile/Microsoft.PowerShell_profile.ps1 $_
}

install_self_signed_ca() {
  log "installing ca"
  sudo cp ./self-signed-root-ca/root-ca.crt /usr/local/share/ca-certificates
  sudo update-ca-certificates
}

install_pwsh() {
  log installing powershell
  sudo apt-get update
  sudo apt-get install -y wget apt-transport-https software-properties-common
  source /etc/os-release
  wget -q https://packages.microsoft.com/config/ubuntu/$VERSION_ID/packages-microsoft-prod.deb
  sudo dpkg -i packages-microsoft-prod.deb
  rm packages-microsoft-prod.deb
  sudo apt-get update
  sudo apt-get install -y powershell
}

install_tools() {
  log "installing tools"
  curl -s https://aliae.dev/install.sh | sudo bash -s
  curl -s https://ohmyposh.dev/install.sh | sudo bash -s
  install_pwsh
  log "tools installed"
}

install() {
  mkdir -p $BIN
  install_gitconfig

  SOURCE="$1"
  log "running with source: ${SOURCE:-default}"
  case "$SOURCE" in
    tools)
      install_tools
      ;;
    *)
      ;;
  esac

  install_pwsh_profile
  install_self_signed_ca

  if is_wsl ; then
    log "running in wsl"
    ensureWinExeSymlink ssh.exe $BIN/wssh
  fi
}

BIN=~/bin
install "$@"
