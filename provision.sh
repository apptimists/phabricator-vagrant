#!/bin/sh

# Fix: "default: stdin: is not a tty" error
# see: https://github.com/mitchellh/vagrant/issues/1673
sed -i '/tty/!s/mesg n/tty -s \\&\\& mesg n/' /root/.profile

# Environment variables
MYSQL_PASSWORD=${MYSQL_PASSWORD}
SERVER_NAME=${SERVER_NAME:-'phabricator.apptimists.com'}
SERVER_ALIAS=${SERVER_ALIAS:-'cdn.apptimists.com'}
SERVER_ADMIN=${SERVER_ADMIN:-'phabricator@apptimists.com'}
MAIL_ADDRESS=${MAIL_ADDRESS:-'phabricator@apptimists.com'}
MAIL_DOMAIN=${MAIL_DOMAIN:-'apptimists.com'}
MAIL_REPLY_PREFIX=${MAIL_REPLY_PREFIX:-'phabricator'}
MAIL_REPLY_DOMAIN=${MAIL_REPLY_DOMAIN:-'apptimists.com'}
SMTP_HOST=${SMTP_HOST:-'mail.apptimists.com'}
SMTP_USER=${SMTP_USER:-'phabricator'}
SMTP_PASSWORD=${SMTP_PASSWORD:-'pass@word1'}
POP3_HOST=${POP3_HOST:-'mail.apptimists.com'}
POP3_USER=${POP3_USER:-'phabricator'}
POP3_PASSWORD=${POP3_PASSWORD:-'pass@word1'}

## Check environment variables
if [ -z "$MYSQL_PASSWORD" ] || [ "$MYSQL_PASSWORD" = "pass@word1" ]
then
  echo '
  Phabricator installation failed! 😱

  Please update the environment variables in Vagrantfile.
  ' >> /dev/stderr
  exit 0
fi

# Basics
apt-get -y update
apt-get -y upgrade

## Set users
adduser phabricator --gecos "" --disabled-password --quiet
adduser phabricator sudo --quiet
adduser git --gecos "" --disabled-password --quiet

## Set permissions
echo '
phabricator ALL=(ALL) SETENV: NOPASSWD: /opt/phabricator
git ALL=(phabricator) SETENV: NOPASSWD: /usr/bin/git-upload-pack, /usr/bin/git-receive-pack, /usr/bin/hg, /usr/bin/svnserve
 www-data ALL=(phabricator) SETENV: NOPASSWD: /usr/bin/git-upload-pack, /usr/lib/git-core/git-http-backend, /usr/bin/hg
 ' >> /etc/sudoers

# Install applications
## Adapted from Phabricator install script: https://raw.githubusercontent.com/phacility/phabricator/master/scripts/install/install_ubuntu.sh
cd /opt

## Install packages
### Supresses password prompt
echo mysql-server-5.5 mysql-server/root_password password $MYSQL_PASSWORD | debconf-set-selections
echo mysql-server-5.5 mysql-server/root_password_again password $MYSQL_PASSWORD | debconf-set-selections
apt-get -y install git mysql-server apache2 dpkg-dev php5 php5-mysql php5-gd php5-dev php5-curl php-apc php5-cli php5-json

### Clone repositories
git clone https://github.com/phacility/libphutil.git
git clone https://github.com/phacility/arcanist.git
git clone https://github.com/phacility/phabricator.git

# Configure Phabricator
cd /opt/phabricator

## General settings
./bin/config set mysql.pass $MYSQL_PASSWORD
./bin/config set phabricator.base-uri 'http://'$SERVER_NAME'/'
./bin/config set phd.user phabricator
./bin/config set environment.append-paths '["/usr/lib/git-core"]'
./bin/config set diffusion.ssh-user git
./bin/config set security.alternate-file-domain	'http://'$SERVER_ALIAS'/'
./bin/config set pygments.enabled true
./bin/config set diffusion.allow-http-auth false
./bin/config set phabricator.show-prototypes true
./bin/config set differential.require-test-plan-field false

## Local file storage settings
mkdir -p /opt/phabricator/files
chmod -R 755 /opt/phabricator/files
chown -R www-data /opt/phabricator/files
chgrp -R www-data /opt/phabricator/files
./bin/config set storage.local-disk.path /opt/phabricator/files

## Repository settings
mkdir -p /opt/phabricator/repositories
chown -R phabricator /opt/phabricator/repositories
chgrp -R phabricator /opt/phabricator/repositories
./bin/config set repository.default-local-path /opt/phabricator/repositories

## Nice to have
apt-get -y install mercurial subversion python-pygments sendmail imagemagick
./bin/config set files.enable-imagemagick true
./bin/config set remarkup.enable-embedded-youtube true

# Setup webserver
echo '
<VirtualHost *:80>
        ServerName '$SERVER_NAME'
        ServerAlias '$SERVER_ALIAS'
        ServerAdmin '$SERVER_ADMIN'
        DocumentRoot /opt/phabricator/webroot
        RewriteEngine on
        RewriteRule ^/rsrc/(.*)     -                       [L,QSA]
        RewriteRule ^/favicon.ico   -                       [L,QSA]
        RewriteRule ^(.*)$          /index.php?__path__=$1  [B,L,QSA]
        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
        <Directory "/opt/phabricator/webroot">
                Require all granted
        </Directory>
</VirtualHost>
' >> /etc/apache2/sites-available/phabricator.conf

a2enmod rewrite
a2dissite 000-default
a2dissite default-ssl
a2ensite phabricator

sed -i 's/^\(;\)\(date\.timezone\s*=\).*$/\2 \"Europe\/Berlin\"/' /etc/php5/apache2/php.ini
sed -i 's/^\(post_max_size\s*=\).*$/\1 32M/' /etc/php5/apache2/php.ini
sed -i 's/^\(;\)\(opcache\.validate_timestamps\s*=\).*$/\20/' /etc/php5/apache2/php.ini

# Clean up virtual hosts
rm /etc/apache2/sites-available/000-default.conf
rm /etc/apache2/sites-available/default-ssl.conf

service apache2 restart

# Setup database
sed -i '/\[mysqld\]/a\#\n# * Phabricator settings\n#\ninnodb_buffer_pool_size=1600M\nsql_mode=STRICT_ALL_TABLES\nft_stopword_file=/home/phd/phabricator/resources/sql/stopwords.txt\nft_boolean_syntax='\'' |-><()~*:""&^'\''\nft_min_word_len=3' /etc/mysql/my.cnf
sed -i 's/^\(max_allowed_packet\s*=\s*\).*$/\132M/' /etc/mysql/my.cnf

service mysql restart

## Install databases
./bin/storage upgrade --force

# Configure SSHd
cp /opt/phabricator/resources/sshd/phabricator-ssh-hook.sh /opt/phabricator-ssh-hook.sh
chown root /opt/phabricator-ssh-hook.sh
chmod 755 /opt/phabricator-ssh-hook.sh
sed -i 's/^\(VCSUSER=\).*$/\1"git"/' /opt/phabricator-ssh-hook.sh
sed -i 's/^\(ROOT=\).*$/\1"\/opt\/phabricator"/' /opt/phabricator-ssh-hook.sh

echo '
Match User git
  AuthorizedKeysCommand /opt/phabricator-ssh-hook.sh
  AuthorizedKeysCommandUser git
  AllowUsers git
  PasswordAuthentication no
' >> /etc/ssh/sshd_config

# Configure email notifications
## Outbound emails
cd /opt/phabricator
./bin/config set metamta.default-address $MAIL_ADDRESS
./bin/config set metamta.domain $MAIL_DOMAIN
./bin/config set metamta.mail-adapter 'PhabricatorMailImplementationPHPMailerAdapter'
./bin/config set phpmailer.smtp-host $SMTP_HOST
./bin/config set phpmailer.smtp-user $SMTP_USER
./bin/config set phpmailer.smtp-password $SMTP_PASSWORD

## Inbound emails
cd /opt/phabricator
./bin/config set metamta.reply-handler-domain $MAIL_REPLY_DOMAIN
./bin/config set metamta.single-reply-handler-prefix $MAIL_REPLY_PREFIX

### Install and configure packages
apt-get -y install fetchmail
pecl install mailparse-2.1.6

echo 'extension=mailparse.so' >> /etc/php5/mods-available/mailparse.ini
php5enmod mailparse

sed -i 's/^\(START_DAEMON=\).*$/\1yes/' /etc/default/fetchmail

echo '
set daemon 30
poll '$POP3_HOST' protocol pop3:
        username "'$POP3_USER'" password "'$POP3_PASSWORD'" is "phabricator" here
        mda "/opt/phabricator/scripts/mail/mail_handler.php"
' >> /etc/fetchmailrc
service fetchmail restart

# (Auto-)Start daemon
echo '
#!/bin/sh -e

# Phabricator

cd /opt/phabricator
exec sudo -En -u phabricator -- ./bin/phd start

exit 0
' >> /etc/rc.local

mkdir -p /var/tmp/phd
chown phabricator /var/tmp/phd
chgrp phabricator /var/tmp/phd

cd /opt/phabricator
exec sudo -En -u phabricator -- ./bin/phd start
