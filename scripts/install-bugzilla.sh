#!/bin/sh
# Setup a Debian/Ubuntu machine for Bugzilla development.

# Update apt cache only after first boot.
if [ ! -f /var/tmp/apt-updated ]
then
    touch /var/tmp/apt-updated
    apt-get update
fi

# Join the www-data and adm groups to facilitate debugging
adduser vagrant www-data # enable access to bugzilla files
adduser vagrant adm      # enable review of apache logs

# Install prerequisite packages (using sqlite3 for development only)
apt-get install -y perl sqlite3 git build-essential unzip apache2 apache2-mpm-prefork

# Install all perl packages from apt
# Note: some may be behind the required version, see below.
apt-get install -y libappconfig-perl libdate-calc-perl libtemplate-perl \
    libmime-perl libdatetime-timezone-perl libdatetime-perl libemail-sender-perl \
    libemail-mime-perl libemail-mime-modifier-perl libdbi-perl libdbd-sqlite3-perl \
    libcgi-pm-perl libmath-random-isaac-perl libmath-random-isaac-xs-perl \
    libapache2-mod-perl2 libapache2-mod-perl2-dev libchart-perl \
    libxml-perl libxml-twig-perl perlmagick libgd-graph-perl libtemplate-plugin-gd-perl\
    libsoap-lite-perl libhtml-scrubber-perl libjson-rpc-perl libdaemon-generic-perl \
    libtheschwartz-perl libtest-taint-perl libauthen-radius-perl libfile-slurp-perl \
    libencode-detect-perl libmodule-build-perl libnet-ldap-perl libauthen-sasl-perl \
    libtemplate-perl-doc libfile-mimeinfo-perl libhtml-formattext-withlinks-perl \
    libgd-dev

# required git configuration
git config --get user.name || git config --global user.name 'Vagrant User'
git config --get user.email || git config --global user.email 'vagrant@example.com'

# Checkout bugzilla from the git repository
if [ ! -d /opt/bugzilla ]
then
    git clone --branch master https://git.mozilla.org/bugzilla/bugzilla /opt/bugzilla
    cd /opt/bugzilla

    # Install any local extensions
    if [ -d /vagrant/extensions ]
    then
        for extn in /vagrant/extensions/*.zip
        do
            (cd /opt/bugzilla/extensions && unzip -oq $extn)
        done
    fi

    # Install any local patches
    [ -d /vagrant/patches ] && git am /vagrant/patches/*.patch
fi

# Add a bugzilla configuration to Apache and enable necessary modules.
a2query -qm cgid || a2enmod cgid
a2query -qm expires || a2enmod expires
a2enmod -qm headers || a2enmod headers
a2query -qm rewrite || a2enmod rewrite
if [ ! $(a2query -qc bugzilla) ]
then
    cat >/etc/apache2/conf-available/bugzilla.conf<<EOF
Alias /Bugzilla /opt/bugzilla/
<Directory /opt/bugzilla/>
  AddHandler cgi-script .cgi
  Options +ExecCGI +FollowSymLinks
  SetEnv no-gzip 1
  DirectoryIndex index.cgi index.html
  AllowOverride Limit FileInfo Indexes Options
  Require all granted
</Directory>
EOF
    a2enconf -q bugzilla && service apache2 reload
fi

# Create a response file to avoid user input in bugzilla configuration
cat >/tmp/bugzilla.responses<<'EOF'
$answer{'create_htaccess'} = 1;
$answer{'webservergroup'} = 'www-data';
$answer{'use_suexec'} = 0;
$answer{'db_driver'} = 'sqlite';
$answer{'db_host'} = 'localhost';
$answer{'db_sock'} = '';
$answer{'db_port'} = 0;
$answer{'db_name'} = 'bugs.db';
$answer{'db_user'} = 'bugs';
$answer{'db_pass'} = 'password';
$answer{'db_check'} = 1;
$answer{'db_mysql_ssl_ca_file'} = '';
$answer{'db_mysql_ssl_ca_path'} = '';
$answer{'db_mysql_ssl_client_cert'} = '';
$answer{'db_mysql_ssl_client_key'} = '';
$answer{'index_html'} = 0;
$answer{'cvsbin'} = '';
$answer{'diffpath'} = '.';
$answer{'interdiffbin'} = '';
$answer{'urlbase'} = 'http://localhost:8080/Bugzilla/';
$answer{'cookiepath'} = '/Bugzilla/';
$answer{'mail_delivery_method'} = 'Test';
$answer{'font_file'} = '';
$answer{'webdotbase'} = '';
$answer{'upgrade_notification'} = 'disabled';
$answer{'ADMIN_EMAIL'} = 'admin@example.com';
$answer{'ADMIN_PASSWORD'} = 'password';
$answer{'ADMIN_REALNAME'} = 'Admin';
$answer{'SMTP_SERVER'} = 'localhost';
$answer{'NO_PAUSE'} = 0;
EOF

# Configure and start bugzilla.
(
  cd /opt/bugzilla
  # NOTE: DateTime::TimeZone requires 1.64 for 5.1-devel but trusty's apt provides 1.63.
  #       Email::Sender requires 1.300011 but trusty's apt provides 1.300010-1
  perl -e 'use DateTime::TimeZone 1.64' 2>/dev/null || perl install-module.pl DateTime::TimeZone
  perl -e 'use Email::Sender 1.300011' 2>/dev/null || perl install-module.pl Email::Sender
  perl -w checksetup.pl /tmp/bugzilla.responses
  echo "Provisioning complete."
  echo "Bugzilla available at http://localhost:8080/Bugzilla/"
)
