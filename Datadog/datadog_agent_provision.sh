#!/bin/bash
#Env
api_key=${api_key} #key for datadog
url="http://`curl v4.ifconfig.co`:8080" #url for web monitoring
web_instance_name=${web_instance_name} #name of web monitoring instance
logs="/var/log/tomcat/catalina.*.log" #file for logs in DD

#install datadog agent
sudo DD_AGENT_MAJOR_VERSION=7 DD_API_KEY=$api_key DD_SITE="datadoghq.com" bash -c "$(curl -L https://s3.amazonaws.com/dd-agent/scripts/install_script.sh)"

#configure web monitoring
sudo tee /etc/datadog-agent/conf.d/http_check.d/conf.yaml <<EOF
instances:
  - name: $web_instance_name
    url: $url
EOF

#enable and configure log agent in DD
sudo sed -i "s/# logs_enabled: false/logs_enabled: true/" /etc/datadog-agent/datadog.yaml
sudo mkdir /etc/datadog-agent/conf.d/logs.d
sudo chown dd-agent:dd-agent /etc/datadog-agent/conf.d/logs.d/
sudo tee /etc/datadog-agent/conf.d/logs.d/conf.yaml <<EOF
logs:
  - type: file
    path: $logs
    service: $web_instance_name
    source: $web_instance_name.agent
EOF

#install and congigure tomcat 
sudo yum install -y tomcat tomcat-webapps tomcat-admin-webapps
sudo sed -i 's@<!-- <user name="admin" password="adminadmin" roles="admin,manager,admin-gui,admin-script,manager-gui,manager-script,manager-jmx,manager-status" /> -->@<user name="admin" password="admin" roles="admin,manager,admin-gui,admin-script,manager-gui,manager-script,manager-jmx,manager-status" />@g' /etc/tomcat/tomcat-users.xml
sudo systemctl enable tomcat
sudo systemctl restart tomcat
sudo chmod -R 775 /var/log/tomcat

sudo systemctl restart datadog-agent
sudo systemctl enable datadog-agent




