## What is this?

These are the dotfiles for the RotorHazard timers on a Raspberry Pi.

## How to install configuration?

```bash
git clone https://github.com/dutchdronesquad/timer-dotfiles.git
cd dotfiles && bash install.sh
```

## Installed packages

The following platforms are installed and set up by default with the bash script:

- GitHub CLI
- Oh My Zsh (with powerlevel10k)
- Pyenv
- Nvm

### Install a python version

```bash
pyenv install --list | grep " 3\.[91011]"
pyenv install 3.10.10
pyenv global 3.10.10
```

### Setup Github account

```bash
git config --global user.name "Dutch Drone Squad"
git config --global user.email "hello@example.com"
```

### Setup Node.JS/NPM

```bash
nvm install 18
nvm use 18
nvm alias default 18