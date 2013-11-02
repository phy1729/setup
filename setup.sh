#!/bin/sh

# Install git and vim
case $(uname -s) in
	Darwin)
		if ! which -s brew; then
			echo "Installing homebrew"
			ruby -e "$(curl -fsSL https://raw.github.com/mxcl/homebrew/go)"
			PATH=$PATH:/usr/local/bin
		fi
		echo "Installing zsh."
		brew install zsh
		if [ ! $(grep '/usr/local/bin/zsh' /etc/shells) ]; then
			echo "Adding zsh to /etc/shells"
			sudo /bin/sh -c 'echo /usr/local/bin/zsh >> /etc/shells'
		fi
		if [ $(dscl /Search -read "/Users/$USER" UserShell | awk '{print $2}') != '/usr/local/bin/zsh' ]; then
			echo "Changing shell to zsh."
			chsh -s "/usr/local/bin/zsh"
		fi
		echo "Installing git."
		brew install git
		echo "Installing vim"
		brew install mercurial
		brew install vim
		echo "Installing tmux"
		brew install tmux
		# Add cronjob to update brew
		line="0	*	*	*	*	/usr/local/bin/brew update 1> /dev/null 2> /dev/null; /usr/local/bin/brew upgrade 1> /dev/null; /usr/local/bin/brew cleanup 1> /dev/null;"
		if ! crontab -l | grep -Fx "$line" - 1>/dev/null; then
			echo "$(crontab -l)\n$line" | crontab -

		fi
		;;

	Linux)
		if [ -x /usr/bin/apt-get ]; then
			install='sudo apt-get -q -y install'
			while true; do
				read -p "Desktop? [y/N] " desktop
				if [ -z "$desktop" ]; then
					desktop=n
				fi
				case "$desktop" in
					Y*|y*)
						desktop=true ;
						vim='vim-gtk'
						break ;;
					N*|n*)
						desktop=false ;
						vim='vim'
						break ;;
				esac
			done

			echo "Installing git."
			$install git
			echo "Installing ntp"
			$install ntp
			echo "Installing tmux"
			$install tmux
			echo "Installing vim"
			$install $vim
			$install curl
			echo "Installing zsh."
			$install zsh
			if [ $(awk -F: "/$(whoami)/"'{print $7}' /etc/passwd) != '/usr/bin/zsh' ]; then
				echo "Changing shell to zsh."
				chsh -s "/usr/bin/zsh"
			fi

			if $desktop; then
				echo "Installing i3"
				$install xserver-xorg xterm xinit i3 xautolock i3lock
				echo "Installing ALSA"
				$install alsa-utils
				echo "Installing calc"
				$install apcalc
				echo "Installing dropbox"
				echo "deb http://linux.dropbox.com/debian squeeze main" | sudo tee /etc/apt/sources.list.d/dropbox.list
				sudo apt-key adv --keyserver pgp.mit.edu --recv-keys 5044912E
				sudo apt-get update > /dev/null
				$install dropbox
				dropbox start -i
				echo "Installing dtrx"
				$install dtrx
				echo "Installing Evince"
				$install evince
				echo "Installing iceweasel"
				echo "deb http://mozilla.debian.net/ wheezy-backports iceweasel-aurora" | sudo tee /etc/apt/sources.list.d/iceweasel.list
				$install pkg-mozilla-archive-keyring
				sudo apt-get update > /dev/null
				sudo apt-get -q -y install -t wheezy-backports iceweasel
				echo "Installing ranger"
				$install ranger
				echo "Installing rdesktop"
				$install rdesktop
				# echo "Installing Steam"
				# http://media.steampowered.com/client/installer/steam.deb
				echo "Installing TeX"
				$install texlive
				wget http://www.info.ucl.ac.be/~pecheur/soft/outlines.sty
				sudo mv outlines.sty /usr/share/texlive/texmf-dist/tex/latex/base/outlines.sty
				sudo texhash
			fi
		else
			echo "Non-apt Linux distro. Exiting"
			exit
		fi
		;;

	OpenBSD)
		if [ -z $PKG_PATH ]; then
			echo "No PKG_PATH set. Using rit.edu."
			export PKG_PATH=ftp://filedump.se.rit.edu/pub/OpenBSD/$(uname -r)/packages/$(uname -p)/
		fi
		echo "Installing zsh."
		sudo pkg_add zsh
		if [ $(awk -F: "/$(whoami)/"'{print $7}' /etc/passwd) != '/usr/local/bin/zsh' ]; then
			echo "Changing shell to zsh."
			chsh -s "/usr/local/bin/zsh"
		fi
		echo "Installing git."
		sudo pkg_add git
		echo "Installing vim"
		sudo pkg_add vim--no_x11
		# OpenBSD comes with tmux
		;;
esac

# Get Dotfiles
if [ ! -f ~/.ssh/id_rsa.pub -a ! -f ~/.ssh/id_dsa.pub ]; then
	echo "No SSH key. Generating one now."
	ssh-keygen -t rsa -b 4096
fi
if [ -f ~/.ssh/id_rsa.pub ]; then
	cat ~/.ssh/id_rsa.pub
else
	cat ~/.ssh/id_dsa.pub
fi

case $(uname -s) in
	OpenBSD)
		read dummyvar?"Copy the key to bitbucket."
		;;
	*)
		read -p "Copy the key to bitbucket." dummyvar
		;;
esac
if [ ! -d ~/.dotfiles ]; then
	echo "Git'ing dotfiles"
	git clone git@bitbucket.org:phy1729/dotfiles.git ~/.dotfiles
else
	git --git-dir=$HOME/.dotfiles/.git/ --work-tree=$HOME/.dotfiles pull --ff-only
fi
~/.dotfiles/bin/dfm

# Update vundle
if [ ! -d ~/.vim/bundle/vundle ]; then
	echo "Git'ing Vundle"
	git clone https://github.com/gmarik/vundle.git ~/.vim/bundle/vundle
fi
vim -u NONE +'silent! source ~/.vimrc' +BundleInstall! +qa
