## What is this?

These are the dotfiles for the RotorHazard timers on a Raspberry Pi. It is recommended
that you install the additional packages only if you are using a Raspberry Pi 4 with
enough RAM, to avoid slowing down your Pi.

## How to install configuration?

```bash
git clone https://github.com/dutchdronesquad/timer-dotfiles.git
cd ~/timer-dotfiles && bash install.sh
```

## Installed packages

The following platforms are installed and set up by default with the bash script:

- GitHub CLI
- Oh My Zsh (with powerlevel10k)
- Pyenv
- Nvm

### Install a python version

```bash
pyenv install --list | grep -E '^  3\.(10|11|12)\.[0-9]+$'
pyenv install 3.11.x
pyenv global 3.11.x
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

### Install / Update RotorHazard

Get RotorHazard and setup an [service](https://github.com/RotorHazard/RotorHazard/blob/main/doc/Software%20Setup.md#running-the-rotorhazard-server).

Run the bash script, it will ask if you want to install or update and which version you want to install.

```bash
cd ~/timer-dotfiles/components && bash rotorhazard.sh
```

#### Development on RotorHazard

If you also want to use the race timer for development purposes, you can use a modified bash script, where you can choose to use your own fork.

```bash
cd ~/timer-dotfiles/components && bash rotorhazard_dev.sh
```

### Change the hostname

For example DDS uses: `dds-rotorhazard[number]` (by default the hostname is `raspberrypi`).

1. Load the raspi-config tool by using the command below

```bash
sudo raspi-config
```

2. Go to `System Options`.
3. Choose for `S4 Hostname`.
4. Change the hostname for something you want.

When you have completed these steps, reboot the Raspberry Pi and you are done.

### Add encryption key to host

1. Create a .ssh folder using `install`.

```bash
install -d -m 700 ~/.ssh
```

2. Create a `authorized_keys` file and paste your public_key into it:

```bash
nano ~/.ssh/authorized_keys
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
