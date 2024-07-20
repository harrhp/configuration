#!/usr/bin/env bash

set -e

log() {
  GREEN='\033[0;32m'
  NC='\033[0m'
  printf "%b%s%b\n" "$GREEN" "$1" "$NC"
}

install_gitconfig() {
  log "installing gitconfig"
  cp ./files/.gitconfig ~/
}

install_pwsh_profile() {
  log "installing pwsh profile"
  mkdir -p ~/.config/powershell/
  cp ./files/Microsoft.PowerShell_profile.ps1 $_
}

install_self_signed_ca() {
  log "installing ca"
  sudo cp ./files/root-ca.crt /usr/local/share/ca-certificates
  sudo update-ca-certificates
}

install() {
  install_gitconfig
  install_pwsh_profile
  install_self_signed_ca
}

install
