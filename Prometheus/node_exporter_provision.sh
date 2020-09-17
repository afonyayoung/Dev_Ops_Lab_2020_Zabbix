#!/bin/bash

sudo yum install -y wget
#download node exporter
wget https://github.com/prometheus/node_exporter/releases/download/v1.0.1/node_exporter-1.0.1.linux-amd64.tar.gz
tar -xvzf node_exporter-1.0.1.linux-amd64.tar.gz 
sudo mv node_exporter-1.0.1.linux-amd64 /etc/node_exporter

#create service node-exporter
sudo tee /etc/systemd/system/node_exporter.service <<EOF
[Unit]
Description=Node Exporter
[Service]
ExecStart=/etc/node_exporter/node_exporter 
[Install]
WantedBy=default.target
EOF

#enable and start service
sudo systemctl daemon-reload
sudo systemctl enable node_exporter.service
sudo systemctl start node_exporter.service