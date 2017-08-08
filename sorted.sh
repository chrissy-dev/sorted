#!/bin/bash
readonly NORMAL='\033[0m'
readonly RED='\033[0;31m'
readonly ERROR_COLOUR=$RED
readonly GREEN='\033[0;32m'
readonly INFO_COLOUR=$GREEN
readonly YELLOW="\033[1;33m"
readonly WARN_COLOUR=$YELLOW
readonly BLUE='\033[0;34m'
readonly LOGFILE=~/sorted.log
readonly BREWLIST=/tmp/brewlist.tmp

function notice {
  # Usage: notice <level> "<message>"
  # Eg: notice SUCCESS "The correct thing has happened"
  #     notice WARN "Something unexpected has happened but it is probably OK"
  #     notice ERROR "Something bad has happened"
  COLOUR=${1}_COLOUR
  echo -e "${!COLOUR}[$1]$NORMAL $2" | tee -a $LOGFILE
}

function info_alert {
  notice INFO "$1"
}

function warn_alert {
  notice WARN "$1"
}

function error_alert {
  notice ERROR "$1"
}

# Adds a string to a file
function append_to_file {
  info_alert "Adding '$1' to $2"
  if grep -F "$1" $2 > /dev/null 2>&1
  then
    warn_alert "Already exists"
  else
    echo "$1" >> $2
  fi
  echo "==============================" >> $LOGFILE
}

# Installs xcode dev tools
function install_xcode {
  info_alert "Installing Xcode command line tools"
  if make -v > /dev/null 2>&1
  then
    warn_alert "Xcode command line tools are already installed"
  else
    echo
    echo -e "  ${RED}Please install via the pop-up dialog box${NORMAL}"
    echo
    xcode-select --install 2>&1 >$LOGFILE
    # TODO Does the license need to be accepted with this?
    #   xcodebuild -license
    read -p "  Press enter to continue after Xcode has installed"
  fi
}

function install_homebrew {
  info_alert "Installing Homebrew"
  if brew -v > /dev/null 2>&1
  then
    warn_alert "Homebrew is already installed"
  else
    ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/install/master/install)" >$LOGFILE 2>&1
    if [[ $? != 0 ]]
    then
      error_alert "Failed to install Homebrew"
      exit 1
    fi
    append_to_file "export PATH='/usr/local/bin:\$PATH'" ~/.zshrc
    source ~/.zshrc >$LOGFILE 2>&1
  fi
  info_alert "Installing/updating Homebrew-Cask"
  brew tap caskroom/cask >$LOGFILE 2>&1
}

function install_ruby_with_rbenv {
  info_alert "Installing ruby 2.3.1"
  RUBY_CONFIGURE_OPTS="--with-zlib-dir=$(brew --prefix zlib)" rbenv install 2.3.1 && rbenv global 2.3.1
    if [[ $? != 0 ]]
    then
      error_alert "Failed to install ruby 2.3.1, check log."
      # exit 1
    fi
}

function install_with_brew {
  if grep "^${1}$" $BREWLIST > /dev/null 2>&1
  then
    warn_alert "$1 is already installed"
    false
  else
    if ! brew install $1 >$LOGFILE 2>&1
    then
      error_alert "Failed to install $1"
    fi
    true
  fi
}

function install_with_cask {
  if grep "^${1}$" $BREWLIST > /dev/null 2>&1
  then
    warn_alert "$1 is already installed"
    false
  else
    brew cask install $1 2>&1 | tee /tmp/casklog.txt >$LOGFILE
    if [[ ${PIPESTATUS[0]} -ne 0 ]]
    then
      if grep "It seems there is already an App at" /tmp/casklog.txt >/dev/null 2>&1
      then
        warn_alert "$1 is already installed."
      else
        error_alert "Failed to install $1"
        exit 1
      fi
    fi
    true
  fi
}

echo "==============================" >> $LOGFILE
echo Started at `date` >> $LOGFILE

Install Dev tools
install_xcode

info_alert "Installing oh-my-zsh"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

source ~/.zshrc >$LOGFILE 2>&1

install_homebrew

for PKG in "$@" #iterm2 atom tower slack google-chrome firefox sketch spectacle
do
  info_alert "Installing $PKG"
  echo "==============================" >> $LOGFILE
  install_with_cask $PKG
done

for PKG in yarn rbenv zlib
do
  info_alert "Installing $PKG"
  echo "==============================" >> $LOGFILE
  install_with_brew $PKG
done

append_to_file 'export PATH="$HOME/.rbenv/bin:$PATH"' ~/.zshrc
append_to_file 'eval "$(rbenv init -)"' ~/.zshrc
source ~/.zshrc >$LOGFILE 2>&1

install_ruby_with_rbenv

info_alert "Installing nvm"
install_with_brew nvm
append_to_file 'export NVM_DIR="$HOME/.nvm"' ~/.zshrc
append_to_file '. "$(brew --prefix nvm)/nvm.sh"' ~/.zshrc
source ~/.zshrc >$LOGFILE 2>&1

echo Ending at `date` >> $LOGFILE
echo "==============================" >> $LOGFILE
