#!/bin/sh
dotfiles_repo="https://github.com/phy1729/dotfiles.git"
needs_ssh=0 # Set to 1 for true

isDesktop() {
	while true; do
		read -p "Desktop? [y/N] " desktop
		if [ -z "$desktop" ]; then
			return 1
		fi
		case "$desktop" in
			Y*|y*)
				return 0;;
			N*|n*)
				return 1;;
		esac
	done
}

makeSSHKey() {
	if [ ! -f ~/.ssh/id_rsa.pub -a ! -f ~/.ssh/id_dsa.pub ]; then
		echo "No SSH key. Generating one now."
		ssh-keygen -t rsa -b 4096
	fi
	if [ -f ~/.ssh/id_rsa.pub ]; then
		cat ~/.ssh/id_rsa.pub
	else
		cat ~/.ssh/id_dsa.pub
	fi
	echo "Copy the key to dotfiles repo"; read dummyvar
}

case $(uname -s) in
	Darwin)
		if ! which -s brew; then
			echo "Installing homebrew"
			ruby -e "$(curl -fsSL https://raw.github.com/mxcl/homebrew/go)"
			PATH=$PATH:/usr/local/bin
		fi
		install='brew install'
		packages='git tmux vim zsh ssh-copy-id'
		cron_line="0	*	*	*	*	/usr/local/bin/brew update 1> /dev/null 2> /dev/null; /usr/local/bin/brew upgrade 1> /dev/null; /usr/local/bin/brew cleanup 1> /dev/null;"
		desired_shell='/usr/local/bin/zsh'
		;;

	Linux)
		if [ -x /usr/bin/pacman ]; then # Arch
			sudo pacman -Syy > /dev/null
			install='sudo pacman --noconfirm -S'
			packages='git ntp tmux zsh'
			desired_shell='/usr/bin/zsh'
		elif [ -x /usr/bin/yum ]; then # CentOS
			install='yum -y install'
			packages='git ntp tmux zsh'
			desired_shell='/bin/zsh'
		elif [ -x /usr/bin/apt-get ]; then #Debian
			install='sudo apt-get -q -y install'
			packages='git ntp tmux zsh'
			desired_shell='/usr/bin/zsh'
			if isDesktop; then
				desktop=true
				packages='xserver-xorg xterm xinit i3 xautolock i3lock alsa-utils apcalc dropbox dtrx evince git ranger rdesktop texlive vim-gtk zsh'
				echo "deb http://linux.dropbox.com/debian squeeze main" | sudo tee /etc/apt/sources.list.d/dropbox.list > /dev/null
				sudo apt-key adv --keyserver pgp.mit.edu --recv-keys 5044912E > /dev/null
				sudo apt-get update > /dev/null
			else
				desktop=
				packages='git vim zsh'
			fi
		else
			echo "Not a supported Linux distro. Exiting"
			exit
		fi
		;;

	OpenBSD)
		if [ -z $PKG_PATH ]; then
			echo "No PKG_PATH set. Using esc7.net"
			export PKG_PATH=http://mirror.esc7.net/pub/OpenBSD/$(uname -r)/packages/$(uname -p)/
		fi
		install='sudo pkg_add'
		packages='git vim--no_x11 zsh'
		desired_shell='/usr/local/bin/zsh'
		;;
esac

for package in $packages; do
	echo "Installing $package"
	$install "$package" > /dev/null
done

if [ -x "$desired_shell" ]; then
	# Mostly needed for Darwin but why not check them all
	if [ ! "$(grep  -Fx "$desired_shell" /etc/shells)" ]; then
		sudo /bin/sh -c 'echo '"$desired_shell"' >> /etc/shells'
	fi
	if [ "$SHELL" != "$desired_shell" ]; then
		echo "Updating login shell"
		chsh -s "$desired_shell"
	fi
fi

if  [ -n "$cron_line" ] && (! crontab -l | grep -Fx "$cron_line" - 1>/dev/null); then
	printf "%s\n%s" "$(crontab -l)" "$cron_line" | crontab -
fi

case $(uname -s) in
	Linux)
		if [ $desktop ]; then
			dropbox start -i
			echo "deb http://mozilla.debian.net/ wheezy-backports iceweasel-aurora" | sudo tee /etc/apt/sources.list.d/iceweasel.list > /dev/null
			$install pkg-mozilla-archive-keyring > /dev/null
			sudo apt-get update > /dev/null
			sudo apt-get -q -y install -t wheezy-backports iceweasel > /dev/null
			# echo "Installing Steam"
			# http://media.steampowered.com/client/installer/steam.deb
			wget -q http://www.info.ucl.ac.be/~pecheur/soft/outlines.sty > /dev/null
			sudo mkdir -p /usr/local/share/texmf/tex/latex/base
			sudo mv outlines.sty /usr/local/share/texmf/tex/latex/base/outlines.sty
			sudo texhash > /dev/null
		fi
		;;
esac

# Get Dotfiles
if [ ${needs_ssh} -eq 1 ]; then
	makeSSHKey
fi
if [ ! -d ~/.dotfiles ]; then
	echo "Git'ing dotfiles"
	git clone --recurse-submodules "${dotfiles_repo}" ~/.dotfiles
else
	git --git-dir=$HOME/.dotfiles/.git/ --work-tree=$HOME/.dotfiles pull --ff-only --recurse-submodules=on-demand
fi
~/.dotfiles/bin/dfm install

# Update plug
if [ ! -f ~/.vim/autoload/plug.vim ]; then
	echo "Getting Plug"
	mkdir -p ~/.vim/autoload
	curl -fLo ~/.vim/autoload/plug.vim https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi
vim -u NONE +'silent! source ~/.vimrc' +PlugUpdate +qa
