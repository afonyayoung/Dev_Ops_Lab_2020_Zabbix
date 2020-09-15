#!/bin/bash

sudo rpm -Uvh https://repo.zabbix.com/zabbix/5.0/rhel/7/x86_64/zabbix-release-5.0-1.el7.noarch.rpm
sudo yum clean all
sudo yum install -y zabbix-agent
sudo cp -p /etc/zabbix/zabbix_agentd.conf /etc/zabbix/zabbix_agentd.conf.bkp
sudo tee /etc/zabbix/zabbix_agentd.conf << EOF
PidFile=/var/run/zabbix/zabbix_agentd.pid
LogFile=/var/log/zabbix/zabbix_agentd.log
LogFileSize=0
Server=$server_ip
ServerActive=${server_ip}
Hostname=$HOSTNAME
HostMetadataItem=system.uname
Include=/etc/zabbix/zabbix_agentd.d/*.conf
EOF

sudo systemctl start zabbix-agent
sudo systemctl enable zabbix-agent

sudo yum install -y tomcat tomcat-webapps tomcat-admin-webapps
sudo sed -i 's@<!-- <user name="admin" password="adminadmin" roles="admin,manager,admin-gui,admin-script,manager-gui,manager-script,manager-jmx,manager-status" /> -->@<user name="admin" password="admin" roles="admin,manager,admin-gui,admin-script,manager-gui,manager-script,manager-jmx,manager-status" />@g' /etc/tomcat/tomcat-users.xml
sudo systemctl enable tomcat
sudo systemctl restart tomcat
sudo chmod -R 775 /var/log/tomcat
