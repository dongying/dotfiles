#!/bin/bash

# Global variables
# Change this varible to choose the targets you want
DOTFILES=( zsh vim git python moc wget )
LINESHIFT="  "
INITED_FILE=".inited"


# Functions
function ln2home() {
    SOURCE="$PWD/$1"
    TARGET="$HOME/.$1"
    if [ -e "$TARGET" ]; then
        if [ $FORCE_SET ]; then
            echo "$TARGET exists, force override it"
            BACKUP="$HOME/.$1.dotfilebak"
            echo "Backup to $BACKUP"
            # To ensure BACKUP is no exist, or may cause link chain recurive
            if [ -e "$BACKUP" ]; then
                rm -rf $BACKUP
            fi
            mv $TARGET $BACKUP
        else
            echo "Unlinked file $TARGET exists, no force, skip"
            return 0
        fi
    elif [ -h "$TARGET" ]; then
        echo "$TARGET is a broken link, rm it"
        rm $TARGET
    fi

    echo "Create link $TARGET -> $SOURCE"
    ln -s $SOURCE $TARGET
}


function installed() {
    if type -P $1 &>/dev/null; then
        echo 1
    else
        return "0"
    fi
}


function install() {
    sudo apt-get install $1
}


function active_install() {
    if [ ! $(installed $1) ]; then
        install $1
    fi
}


function impl_zsh() {
    active_install zsh
    ln2home oh-my-zsh
    ln2home zshrc
    # Will cause error since in bash environment
    # source "$HOME/.zshrc"
}


function impl_vim() {
    active_install vim
    active_install ctags
    ln2home vim
    ln2home vimrc
    (
    vim +BundleInstall +qall
    )
}


function impl_git() {
    ln2home gitconfig
    ln2home gitignore_global
}


function impl_python() {
    # echo "Install Python"
    # echo "Install virtualenv"
    echo ".pystartup"
    ln2home pystartup
}


function impl_moc() {
    active_install mocp
    ln2home moc
}


function impl_wget() {
    active_install wget
    ln2home wgetrc
}


function update() {
    git pull
    git submodule init
    git submodule update
}


function conf_zsh() {
    local user="$(whoami)"
    read -p "Do you want to set to this user $user(yourself) [yY]?" -n 1
    if [[ $REPLY =~ ^[Yy]$ || ! $REPLY ]]; then
        echo
        read -p "input username: " $user
    fi
    sudo usermod -s /bin/zsh $user
}


# Preparations
if [ ! $(installed git) ]; then
    echo 'git must be installed !'
    exit
fi

cd "$(dirname "$0")"

# Main
if [ "$1" == "help" ]; then
    echo
    echo "Avaliable commands:"
    echo "${LINESHIFT}init [-f, --force]    : initialize dotfiles"
    echo "${LINESHIFT}reset name   : reset one dotfiles, override existing"
    echo "${LINESHIFT}update   : update things that can be updated"
elif [ "$1" == "test" ]; then
    echo "test"
    if [ $(cmd_installed chrome) ]; then
        echo 'ok0'
    fi
    if [ $(cmd_installed make) ]; then
        echo 'ok1'
    fi
else
    # Following options needs repos to be inited & updated,
    # let's do the check
    if [ ! -e $INITED_FILE ]; then
        echo "init repos first"
        update
        touch $INITED_FILE
        # If this is done before command `update`,
        # there will be no need to redo update,
        # set a flag for later use.
        FIRST_TIME="true"
    fi

    if [ "$1" == "init" ]; then

        # Get force option
        if [ "$2" == "--force" -o "$2" == "-f" ]; then
            echo "set force to true"
            FORCE_SET="true"
        fi

        echo "start implementing"

        # Implementation starts
        for i in ${DOTFILES[@]}; do
            echo "Setting $i's dotfiles"
            eval "impl_$i"
        done
        echo
        echo "All done!"
    elif [ "$1" == "reset" ]; then
        if [ -z $2 ]; then
            echo "Please input the second argumenet"
            exit
        fi
        echo "reset"
        FORCE_SET="true"
        eval "impl_$2"
    elif [ "$1" == "update" ]; then
        if [ $FIRST_TIME ]; then
            echo "already updated just now"
        else
            echo "update"
            update
            echo "done"
        fi
    elif [ "$1" == "configure" ]; then
        echo "configure"
        if [ -z $2 ]; then
            echo "Please input the second argumenet"
            exit
        fi
        echo "reset"
        eval "conf_$2"
    else
        echo "Please input a valid command"
    fi
fi