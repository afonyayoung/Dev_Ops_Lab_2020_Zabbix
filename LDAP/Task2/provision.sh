#!/bin/bash
sudo yum install -y openldap openldap-servers openldap-clients
sudo systemctl start slapd
sudo systemctl enable slapd
sudo firewall-cmd --add-service=ldap

slappasswd -s password > passwd
admin_paswd=`cat passwd`

#cofigure ldap server
cat <<EOT >ldaprootpasswd.ldif
dn: olcDatabase={0}config,cn=config
changetype: modify
add: olcRootPW
olcRootPW:$admin_paswd
EOT
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f ldaprootpasswd.ldif 

sudo cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
sudo chown -R ldap:ldap /var/lib/ldap/DB_CONFIG
sudo systemctl restart slapd
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif 
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif

cat <<EOT > openssh-lpk.ldif
dn: cn=openssh-lpk,cn=schema,cn=config
objectClass: olcSchemaConfig
cn: openssh-lpk
olcAttributeTypes: ( 1.3.6.1.4.1.24552.500.1.1.1.13 NAME 'sshPublicKey' 
  DESC 'MANDATORY: OpenSSH Public key' 
  EQUALITY octetStringMatch
  SYNTAX 1.3.6.1.4.1.1466.115.121.1.40 )
olcObjectClasses: ( 1.3.6.1.4.1.24552.500.1.1.2.0 NAME 'ldapPublicKey' SUP top AUXILIARY
  DESC 'MANDATORY: OpenSSH LPK objectclass'
  MAY ( sshPublicKey $ uid ) 
  )
EOT
ldapadd -Y EXTERNAL -H ldapi:/// -f openssh-lpk.ldif

cat <<EOT >ldapdomain.ldif
dn: olcDatabase={1}monitor,cn=config
changetype: modify
replace: olcAccess
olcAccess: {0}to * by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" read by dn.base="cn=Manager,dc=devopslab,dc=com" read by * none

dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: dc=devopslab,dc=com

dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcRootDN
olcRootDN: cn=Manager,dc=devopslab,dc=com

dn: olcDatabase={2}hdb,cn=config
changetype: modify
add: olcRootPW
olcRootPW: $admin_paswd

dn: olcDatabase={2}hdb,cn=config
changetype: modify
add: olcAccess
olcAccess: {0}to attrs=userPassword,shadowLastChange by
  dn="cn=Manager,dc=devopslab,dc=com" write by anonymous auth by self write by * none
olcAccess: {1}to dn.base="" by * read
olcAccess: {2}to * by dn="cn=Manager,dc=devopslab,dc=com" write by * read
EOT
sudo ldapmodify -Y EXTERNAL -H ldapi:/// -f ldapdomain.ldif

cat <<EOT >baseldapdomain.ldif
dn: dc=devopslab,dc=com
objectClass: top
objectClass: dcObject
objectclass: organization
o: devopslab com
dc: devopslab

dn: cn=Manager,dc=devopslab,dc=com
objectClass: organizationalRole
cn: Manager
description: Directory Manager

dn: ou=People,dc=devopslab,dc=com
objectClass: organizationalUnit
ou: People

dn: ou=Group,dc=devopslab,dc=com
objectClass: organizationalUnit
ou: Group
EOT
sudo ldapadd -x -D cn=Manager,dc=devopslab,dc=com -w password -f baseldapdomain.ldif

cat <<EOT >ldapgroup.ldif
dn: cn=Manager,ou=Group,dc=devopslab,dc=com
objectClass: top
objectClass: posixGroup
gidNumber: 1005
EOT
sudo ldapadd -x  -w password -D "cn=Manager,dc=devopslab,dc=com" -f ldapgroup.ldif

cat <<EOT > ldapuser.ldif
dn: uid=my_user,ou=People,dc=devopslab,dc=com
objectClass: top
objectClass: account
objectClass: posixAccount
objectClass: shadowAccount
obJectClass: ldapPublicKey
cn: my_user
uid: my_user
uidNumber: 1005
gidNumber: 1005
homeDirectory: /home/my_user
userPassword: $admin_paswd
loginShell: /bin/bash
gecos: my_user
shadowLastChange: 0
shadowMax: -1
shadowWarning: 0
sshPublicKey: ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDZDH1iUMezsnm1yg4OXovP+l8TCt2VHtgyz6w/j+hKrZqIYb8CvUhmpbje3E0ObCQ/za7tTCOu2F2QAJ1fpr5P05Wl1xPtAe28n2MbwZcGe3RjjtQKYo23/B13hQyAZrBgSaOL7gOhZVcbW2PFpm8f5yOjZbAXRnTZBIcN2vRHDJBM8lEdqEU3I7/2W/CBSyo8z3JFVyXyreCOgBBPC8lDZ/8iR9iJQSGEPqLjB4QBUHiYnrfYyPuvz7xxWdPBnYVktodFRlfrEcvdZjfmFtQJ34SqBHEi4ePzFAn78QazfwZ18f1KwJvdcaLwR+V4lRKfITCt0x/2Ikgjp+Bm9xk9nxbsqS1tx9VRC/eqxxiOkSHUgiuEd4ckY+WfBrS1twHMR7dQuV76ch+OU1z8mtnD0+7qfFMCpNBKbQhIc7pZoNBAypmpNihXQJWaITo7TlqdvM7Qx1w1Qf21KNBiMXe5AbUWj8t0CJS9+fbVVDi2UzJyaTMo/zZrDcbkyGz5E1c= Alexey@Probook
EOT
sudo ldapadd -x -D cn=Manager,dc=devopslab,dc=com -w password -f  ldapuser.ldif

#install and cogigure GUI ldapadmin
sudo yum --enablerepo=epel -y install phpldapadmin
sudo sed -i "/\$servers->setValue('login','attr','uid');/s/^/\/\//" /etc/phpldapadmin/config.php
sudo sed -i "s@\/\/\$servers->setValue('login','attr','dn');@\$servers->setValue('login','attr','dn');@g" /etc/phpldapadmin/config.php
sudo sed -i '/Require local/a\\tRequire all granted' /etc/httpd/conf.d/phpldapadmin.conf
sudo systemctl restart httpd
sudo rm -f *.ldif passwd
