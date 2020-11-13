cd "$(dirname "$0")/.."
DOTFILES_ROOT=$(pwd -P)

. ./print.sh --source-only
. ./install_nvim.sh --source-only
. ./homebrew.sh --source-only

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

change_shell() {
    chsh -s $(which zsh)
}

install_antibody() {
    which -s antibody
    if [[ $? != 0 ]] ; then
        info "Installing Antibody for you"
        brew install getantibody/tap/antibody > /dev/null 2>&1
    fi
}

install_zsh() {
    info "Setting up ZSH for you"
    brew list zsh || brew install zsh > /dev/null 2>&1
    if ! grep -Fxq $(which zsh) /etc/shells
        then
            sudo sh -c "echo $(which zsh) >> /etc/shells"
    fi
    install_antibody
    change_shell
    success "ZSH and Antibody set up"
}

install_extras() {
    brew install Schniz/tap/fnm > /dev/null 2>&1 # Fast Node Manager
    brew install autojump > /dev/null 2>&1
    brew install tree > /dev/null 2>&1
    brew install terminal-notifier > /dev/null 2>&1
    brew install coreutils > /dev/null 2>&1
    brew install gpatch > /dev/null 2>&1
    brew install kubernetes-cli > /dev/null 2>&1
    brew install helm > /dev/null 2>&1
    brew install kops > /dev/null 2>&1
    brew install neovim > /dev/null 2>&1
    success "Finished setting up extras"
}

install_reason_basics() {
    info "Setting up Opam"
    brew install opam > /dev/null 2>&1
    opam create switch 4.06.1
    echo "y" | opam switch 4.06.1
    echo "y" | opam install merlin reason
    opam init
    success "Opam set up"
}

get_basics() {
    info "Installing Dependencies"
    install_zsh
    install_extras
    install_opam
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

echo "Are you sure you want to install these opinionated dotfiles? (y/n)"; read answer
if [[ $answer != "n" ]] && [[ $answer != "N" ]] ; then
    check_brew
    hasbrew=$?
    if [ "$hasbrew" == 0 ]
    then
    get_brew
    get_basics
    link_shell_rcs
    link_emacs
    link_neovim
    success "Finished setting up dotfiles. Please config .localrc and restart terminal."
fi
