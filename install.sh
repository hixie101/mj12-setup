#!/bin/bash

# Exit immediately if any command fails
set -e

echo "=== Step 1: Mount CD drive ==="
sudo mount /dev/cdrom /mnt

echo "=== Step 2: Install XE Guest Tools ==="
sudo bash /mnt/Linux/install.sh -y

echo "=== Step 3: Downloading MJ12Node ==="
wget -q --show-progress https://majestic12.co.uk/files/mj12node/mono/mj12node_linux_v1722_net471.tgz

echo "=== Step 4: Extracting files ==="
tar xzvf mj12node_linux_v1722_net471.tgz

echo "=== Step 5: Installing initial dependencies ==="
sudo apt update
sudo apt install -y ca-certificates gnupg

echo "=== Step 6: Adding Mono repository keys ==="
sudo gpg --homedir /tmp --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/mono-official-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
sudo chmod +r /usr/share/keyrings/mono-official-archive-keyring.gpg

echo "=== Step 7: Configuring Mono repository ==="
echo "deb [signed-by=/usr/share/keyrings/mono-official-archive-keyring.gpg] https://download.mono-project.com/repo/ubuntu stable-focal main" | sudo tee /etc/apt/sources.list.d/mono-official-stable.list

echo "=== Step 8: Updating system packages ==="
sudo apt update && sudo apt dist-upgrade -y

echo "=== Step 9: Installing Mono ==="
sudo apt install -y mono-complete

echo "=== Step 10: Installing and enabling Cron ==="
sudo apt install -y nano cron
sudo systemctl enable cron
sudo systemctl start cron

echo "=== Step 11: Creating reboot.sh script ==="
mkdir -p /home/hixie/MJ12node
sudo tee /home/hixie/MJ12node/reboot.sh > /dev/null << 'EOF'
#!/bin/bash
sleep $(shuf -i 43200-86400 -n 1)s && sudo reboot
EOF
sudo chmod +x /home/hixie/MJ12node/reboot.sh

echo "=== Step 12: Injecting Root Cron job natively ==="
# Appends the reboot task directly into the root crontab without opening the text editor
echo "@reboot /home/hixie/MJ12node/reboot.sh" | sudo tee -a /var/spool/cron/crontabs/root > /dev/null

# Verifies the injection by listing the root crontab
sudo crontab -l

echo "=== Step 13: Creating startup.sh script ==="
sudo tee /home/hixie/MJ12node/startup.sh > /dev/null << 'EOF'
#!/bin/sh
sleep 30
sudo mono /home/hixie/MJ12node/MJ12nodeMono.exe
EOF
sudo chmod +x /home/hixie/MJ12node/startup.sh

echo "=== Step 14: Creating Systemd Service ==="
sudo tee /etc/systemd/system/mj12.service > /dev/null << 'EOF'
[Unit]
Description=Virtual Distributed Ethernet

[Service]
ExecStart=/home/hixie/MJ12node/startup.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo "=== Step 15: Starting and enabling mj12 service ==="
sudo systemctl daemon-reload
sudo systemctl enable mj12.service
sudo systemctl start mj12.service

echo "=== Step 16: Verifying service status ==="
sudo systemctl status mj12.service --no-pager

echo "=== Setup complete! Please run sudo mono /home/hixie/MJ12node/MJ12nodeMono.exe manually to configure MJ12 client ==="
