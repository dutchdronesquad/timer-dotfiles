## What is this?

These are the dotfiles for the RotorHazard timers on a Raspberry Pi.

## How to install configuration?

```bash
git clone https://github.com/dutchdronesquad/timer-dotfiles.git
cd timer-dotfiles && bash install.sh
```

## Installed packages

The following platforms are installed and set up by default with the bash script:

- GitHub CLI
- Oh My Zsh (with powerlevel10k)
- Pyenv (Raspberry Pi 4)
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
```

### Install RotorHazard

Get RotorHazard and setup an [service](https://github.com/RotorHazard/RotorHazard/blob/main/doc/Software%20Setup.md#running-the-rotorhazard-server)

```bash
cd ~/timer-dotfiles/components && bash rotorhazard.sh
```

### Change the network interface priority

The race timers are wired to our local intranet network by default, however when a
Raspberry Pi is also connected to Wi-Fi it gives priority to the ethernet interface
by default. However, this causes problems in the way we work during the training events.

![alt network diagram](https://raw.githubusercontent.com/dutchdronesquad/timer-dotfiles/main/assets/DDS-Network.png)

So we change the interface preference in the **dhcpcd**:

```bash
sudo nano /etc/dhcpcd.conf
```

Change and add the following lines:

```bash
interface eth0
metric 350
```

__Note:__ The metric is the priority of the interface. The lower the number, the higher the priority.

You can check the current priority of the interfaces with the following command:

```bash
ip route show
```

Restart the dhcpcd service:

```bash
sudo systemctl restart dhcpcd
```
