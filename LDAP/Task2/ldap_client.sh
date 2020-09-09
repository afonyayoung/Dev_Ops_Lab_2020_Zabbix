#!/bin/bash
#install and configure ldap client
sudo yum -y install openldap-clients nss-pam-ldapd
sudo authconfig --enableldap --enableldapauth --ldapserver=${server_ip} --ldapbasedn="dc=devopslab,dc=com" --enablemkhomedir --update

#configure ssh daemon
sudo sed -i "/\PasswordAuthentication no/s/^/\#/" /etc/ssh/sshd_config
sudo sed -i "s@\#PasswordAuthentication yes@PasswordAuthentication yes@g" /etc/ssh/sshd_config
sudo sed -i "s@\#AuthorizedKeysCommand none@AuthorizedKeysCommand /opt/ssh_ldap.sh@g" /etc/ssh/sshd_config
sudo sed -i "s@\#AuthorizedKeysCommandUser nobody@AuthorizedKeysCommandUser nobody@g" /etc/ssh/sshd_config 

#create script for ssh daemon
sudo tee /opt/ssh_ldap.sh <<EOF
#!/bin/bash
set -eou pipefail
IFS=$'\n\t'

result=\$(ldapsearch -x '(&(objectClass=posixAccount)(uid='"\$1"'))' 'sshPublicKey')
attrLine=\$(echo "\$result" | sed -n '/^ /{H;d};/sshPublicKey:/x;\$g;s/\n *//g;/sshPublicKey:/p')

if [[ "\$attrLine" == sshPublicKey::* ]]; then
  echo "\$attrLine" | sed 's/sshPublicKey:: //' | base64 -d
elif [[ "\$attrLine" == sshPublicKey:* ]]; then
  echo "\$attrLine" | sed 's/sshPublicKey: //'
else
  exit 1
fi
EOF
sudo chmod +x /opt/ssh_ldap.sh

#restart services
sudo systemctl restart nslcd
sudo systemctl restart sshd