#!/usr/bin/env bash

cp ./gitconfig/.gitconfig ~/

if command -v aliae > /dev/null && command -v oh-my-posh > /dev/null ; then
  PROFILE=~/.profile
  sed -i "/^# dotfiles$/,/^# dotfiles$/d" $PROFILE
  echo \
  '# dotfiles
export ALIAE_CONFIG="https://raw.githubusercontent.com/harrhp/configuration/HEAD/shell/aliae.yaml"
eval "$(aliae init bash)"
# dotfiles' >> $PROFILE
fi

sudo cp ./self-signed-root-ca/root-ca.crt /usr/local/share/ca-certificates
sudo update-ca-certificates

if [ -n "${WSL_DISTRO_NAME+isset}" ] ; then
  BIN=~/bin
  mkdir -p $BIN

  ensureWinExeSymlink() {
    mkdir -p $(dirname "$2")
    winExePath=$(command -v $1)
    if [ -f "$winExePath" ] ; then
      rm -f "$2" && ln -s "$winExePath" "$2"
    fi
  }

  ensureWinExeSymlink ssh.exe $BIN/wssh
fi
