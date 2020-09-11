#!/bin/bash
#install and configure tomcat 
sudo yum install -y tomcat tomcat-webapps tomcat-admin-webapps
sudo sed -i 's@<!-- <user name="admin" password="adminadmin" roles="admin,manager,admin-gui,admin-script,manager-gui,manager-script,manager-jmx,manager-status" /> -->@<user name="admin" password="admin" roles="admin,manager,admin-gui,admin-script,manager-gui,manager-script,manager-jmx,manager-status" />@g' /etc/tomcat/tomcat-users.xml
sudo systemctl enable tomcat
sudo systemctl restart tomcat

#install and configure logstash
sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
sudo tee //etc/yum.repos.d/logstash.repo <<EOF
[logstash-7.x]
name=Elastic repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF

sudo  yum install -y logstash
sudo tee /etc/logstash/conf.d/tomcat.conf <<EOF
input {
  file {
    path => "/var/log/tomcat/*"
    start_position => "beginning"
  }
}

output {
  elasticsearch {
    hosts => ["${server_ip}:9200"]
  }
  stdout { codec => rubydebug }
}
EOF
sudo chmod -R 775 /var/log/tomcat
sudo systemctl enable logstash.service
sudo systemctl restart logstash.service