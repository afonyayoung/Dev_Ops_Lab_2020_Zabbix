#!/bin/bash
#install and configure tomcat 
sudo yum install -y tomcat tomcat-webapps tomcat-admin-webapps
sudo sed -i 's@<!-- <user name="admin" password="adminadmin" roles="admin,manager,admin-gui,admin-script,manager-gui,manager-script,manager-jmx,manager-status" /> -->@<user name="admin" password="admin" roles="admin,manager,admin-gui,admin-script,manager-gui,manager-script,manager-jmx,manager-status" />@g' /etc/tomcat/tomcat-users.xml
sudo systemctl enable tomcat
sudo systemctl restart tomcat
