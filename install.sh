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
			success "moved $2 to $2.backup"
		fi
	fi
	ln -sf "$1" "$2"
	success "linked $1 to $2"
}

get_brew() {
    info "Checking for Brew"
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

install_zsh() {
    brew list zsh || brew install zsh > /dev/null 2>&1
    if ! grep -Fxq $(which zsh) /etc/shells
        then
            sudo sh -c "echo $(which zsh) >> /etc/shells"
    fi
}

install_antibody() {
    which -s antibody
    if [[ $? != 0 ]] ; then
        info "Installing Antibody for you"
        brew install getantibody/tap/antibody > /dev/null 2>&1
    fi
}

install_extras() {
    brew install autojump > /dev/null 2>&1
    brew install tree > /dev/null 2>&1
    brew install terminal-notifier > /dev/null 2>&1
    brew install coreutils > /dev/null 2>&1
    brew install gpatch > /dev/null 2>&1
    brew install opam > /dev/null 2>&1
    brew install emacs-mac-spacemacs-icon
    git clone https://github.com/syl20bnr/spacemacs ~/.emacs.d
    opam init
    success "Finished setting up extras"
}

get_basics() {
    info "Installing Dependencies"
    install_zsh
    install_antibody
    install_extras
}


change_shell() {
    chsh -s $(which zsh)
}

echo "Are you sure you want to install Bragi's dotfiles? (y/n)"; read answer
if [[ $answer != "n" ]] && [[ $answer != "N" ]] ; then
    get_brew
    get_basics
    link_file $DOTFILES_ROOT/.dotfiles/zshrc.symlink $HOME/.zshrc
    change_shell
    success "Finished setting up Bragi's humble dotfiles. Please restart terminal."
fi
