#==============
# Install all the packages
#==============
cd "$(dirname "$0")/.."
DOTFILES_ROOT=$(pwd -P)

success() {
	# shellcheck disable=SC2059
	printf "\r\033[2K  [\033[00;32mOK\033[0m] $1\n"
}

info() {
	# shellcheck disable=SC2059
	printf "\r  [\033[00;34m..\033[0m] $1\n"
}

link_file() {
	if [ -e "$2" ]; then
		if [ "$(readlink "$2")" = "$1" ]; then
			success "skipped $1"
			return 0
		else
			mv "$2" "$2.backup"
            #echo "$2" "$2.backup"
			success "moved $2 to $2.backup"
		fi
	fi
	ln -sf "$1" "$2"
    #echo "-sf" "$1" "$2"
	success "linked $1 to $2"
}

get_brew() {
    which -s brew
    if [[ $? != 0 ]] ; then
        # Install Homebrew
        info "Installing Homebrew"
        ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
        success "Homebrew installed"
    else
        info "Updating Homebrew"
        brew doctor
        brew update
        success "Finished updating Homebrew"
    fi
}

get_basics() {
    info "Installing Dependencies"
    brew install getantibody/tap/antibody
    brew install terminal-notifier
    brew install coreutils
}

echo "Install all base packages (Y/n) => "; read answer
if [[ $answer != "n" ]] && [[ $answer != "N" ]] ; then
    info "Checking for Brew"
    
    get_brew
    get_basics
    link_file $DOTFILES_ROOT/.dotfiles/.zshrc.symlink $HOME/.zshrc
    success "Finished setting up simple dotfiles"
fi