#!/bin/bash
password=password
network_range=10.1.1.0/24

#install mariadb
sudo yum install -y mariadb mariadb-server
sudo /usr/bin/mysql_install_db --user=mysql
sudo systemctl start mariadb
sudo systemctl enable mariadb

#configure mariadb
mysql -uroot <<EOT
create database zabbix character set utf8 collate utf8_bin;
grant all privileges on zabbix.* to zabbix@localhost identified by '$password'; 
EOT

#install and configure zabbix
sudo rpm -Uvh https://repo.zabbix.com/zabbix/5.0/rhel/7/x86_64/zabbix-release-5.0-1.el7.noarch.rpm
sudo yum clean all
sudo yum install -y zabbix-server-mysql zabbix-agent
sudo yum install -y centos-release-scl
sudo sed -i "0,/enabled=0/s/enabled=0/enabled=1/" /etc/yum.repos.d/zabbix.repo
sudo yum install -y zabbix-web-mysql-scl zabbix-apache-conf-scl
sudo zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -uzabbix --password=$password zabbix

#make backup for zabbix-server config
sudo cp -p /etc/zabbix/zabbix_server.conf /etc/zabbix/zabbix_server.conf.bkp

#change zabbix server configuration
sudo tee /etc/zabbix/zabbix_server.conf <<EOF 
LogFile=/var/log/zabbix/zabbix_server.log
LogFileSize=0
PidFile=/var/run/zabbix/zabbix_server.pid
SocketDir=/var/run/zabbix
DBHost=localhost
DBName=zabbix
DBUser=zabbix
DBPassword=$password
SNMPTrapperFile=/var/log/snmptrap/snmptrap.log
Timeout=4
AlertScriptsPath=/usr/lib/zabbix/alertscripts
ExternalScripts=/usr/lib/zabbix/externalscripts
LogSlowQueries=3000
StatsAllowedIP=$network_range
EOF

#change time zone
sudo sed -i "s/; php_value\[date.timezone\] = Europe\/Riga/php_value[date.timezone] = Europe\/Minsk/" /etc/opt/rh/rh-php72/php-fpm.d/zabbix.conf

#make config for skip web preinstall 
sudo tee /etc/zabbix/web/zabbix.conf.php <<EOF
<?php
// Zabbix GUI configuration file.
\$DB['TYPE']                             = 'MYSQL';
\$DB['SERVER']                   = 'localhost';
\$DB['PORT']                             = '0';
\$DB['DATABASE']                 = 'zabbix';
\$DB['USER']                             = 'zabbix';
\$DB['PASSWORD']                 = '$password';
// Schema name. Used for PostgreSQL.
\$DB['SCHEMA']                   = '';
// Used for TLS connection.
\$DB['ENCRYPTION']               = false;
\$DB['KEY_FILE']                 = '';
\$DB['CERT_FILE']                = '';
\$DB['CA_FILE']                  = '';
\$DB['VERIFY_HOST']              = false;
\$DB['CIPHER_LIST']              = '';
// Use IEEE754 compatible value range for 64-bit Numeric (float) history values.
// This option is enabled by default for new Zabbix installations.
// For upgraded installations, please read database upgrade notes before enabling this option.
\$DB['DOUBLE_IEEE754']   = true;
\$ZBX_SERVER                             = 'localhost';
\$ZBX_SERVER_PORT                = '10051';
\$ZBX_SERVER_NAME                = '$HOSTNAME';
\$IMAGE_FORMAT_DEFAULT   = IMAGE_FORMAT_PNG;
// Uncomment this block only if you are using Elasticsearch.
// Elasticsearch url (can be string if same url is used for all types).
//\$HISTORY['url'] = [
//      'uint' => 'http://localhost:9200',
//      'text' => 'http://localhost:9200'
//];
// Value types stored in Elasticsearch.
//\$HISTORY['types'] = ['uint', 'text'];
// Used for SAML authentication.
// Uncomment to override the default paths to SP private key, SP and IdP X.509 certificates, and to set extra settings.
//\$SSO['SP_KEY']                        = 'conf/certs/sp.key';
//\$SSO['SP_CERT']                       = 'conf/certs/sp.crt';
//\$SSO['IDP_CERT']              = 'conf/certs/idp.crt';
//\$SSO['SETTINGS']              = [];
EOF

#disable selinux
sudo setenforce 0
sudo sed -i 's/enforcing/disabled/g' /etc/selinux/config

#restart all services
sudo systemctl restart zabbix-server httpd rh-php72-php-fpm zabbix-agent
sudo systemctl enable zabbix-server httpd rh-php72-php-fpm zabbix-agent