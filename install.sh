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
    brew install Schniz/tap/fnm > /dev/null 2>&1
    brew install autojump > /dev/null 2>&1
    brew install tree > /dev/null 2>&1
    brew install terminal-notifier > /dev/null 2>&1
    brew install coreutils > /dev/null 2>&1
    brew install gpatch > /dev/null 2>&1
    brew install opam > /dev/null 2>&1
    brew tap railwaycat/emacsmacport > /dev/null 2>&1
    brew install emacs-mac > /dev/null 2>&1
    brew untap railwaycat/emacsmacport > /dev/null 2>&1
    brew install kubernetes-cli > /dev/null 2>&1
    brew install helm > /dev/null 2>&1
    brew install kops > /dev/null 2>&1
    brew install neovim > /dev/null 2>&1
    brew install the_silver_searcher > /dev/null 2>&1
    git clone https://github.com/syl20bnr/spacemacs ~/.emacs.d
    opam init
    success "Finished setting up extras"
}

install_reason_basics() {
    opam create switch 4.06.1
    echo "y" | opam switch 4.06.1
    echo "y" | opam install merlin reason
}

get_basics() {
    info "Installing Dependencies"
    install_zsh
    install_antibody
    install_extras
    install_reason_basics
}

change_shell() {
    chsh -s $(which zsh)
}

link_shell_rcs() {
    link_file $DOTFILES_ROOT/.dotfiles/zshrc.symlink $HOME/.zshrc
    cp $DOTFILES_ROOT/.dotfiles/config/localrc.bootstrap $HOME/.localrc
}

link_emacs() {
    rm -rf $HOME/.emacs.d
    mkdir $HOME/.emacs.d
    link_file $DOTFILES_ROOT/.dotfiles/emacs/init.el $HOME/.emacs.d/init.el
}

echo "Are you sure you want to install Bragi's dotfiles? (y/n)"; read answer
if [[ $answer != "n" ]] && [[ $answer != "N" ]] ; then
    get_brew
    get_basics
    link_shell_rcs
    link_emacs
    change_shell
    success "Finished setting up Bragi's humble dotfiles. Please config .localrc and restart terminal."
fi
