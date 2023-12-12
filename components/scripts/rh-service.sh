#!/bin/bash
echo "INFO: Setup Rotorhazard service"

if [ -f "/lib/systemd/system/rotorhazard.service" ]; then
    echo "ERROR: Rotorhazard service already exists."
else 
    sed -i -e 's/pi/'$USER'/g' ~/timer-dotfiles/components/resources/rotorhazard.service

    # Note you will need to update the rotorhazard.service file if you are not using the pi username
    sudo cp ~/timer-dotfiles/components/resources/rotorhazard.service /lib/systemd/system/rotorhazard.service
    sudo chmod 644 /lib/systemd/system/rotorhazard.service

    # Reload the daemon and enable
    sudo systemctl daemon-reload
    sudo systemctl enable rotorhazard.service

    # Start the service
    sudo systemctl start rotorhazard.service
fi
echo "DONE: Service has been created"