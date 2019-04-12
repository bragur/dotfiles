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

install_diff_so_fancy() {
    echo "Do you want to setup diff-so-fancy for a nicer git diff experience? (y/n) "; read answer
    if [[ $answer != "n" ]] && [[ $answer != "N" ]] ; then
        brew install diff-so-fancy > /dev/null 2>&1
        git config --global core.pager "diff-so-fancy | less --tabs=4 -RFX"
        git config --global color.ui true
        git config --global color.diff-highlight.oldNormal    "red bold"
        git config --global color.diff-highlight.oldHighlight "red bold 52"
        git config --global color.diff-highlight.newNormal    "green bold"
        git config --global color.diff-highlight.newHighlight "green bold 22"
        git config --global color.diff.meta       "yellow"
        git config --global color.diff.frag       "magenta bold"
        git config --global color.diff.commit     "yellow bold"
        git config --global color.diff.old        "red bold"
        git config --global color.diff.new        "green bold"
        git config --global color.diff.whitespace "red reverse"
        success "Diff So Fancy setup complete"
    fi
}

install_extras() {
    brew install autojump > /dev/null 2>&1
    brew install tree > /dev/null 2>&1
    brew install terminal-notifier > /dev/null 2>&1
    brew install coreutils > /dev/null 2>&1
    install_diff_so_fancy
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
