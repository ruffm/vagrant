s root

read -p "Enter your username: " username

echo -e "Updating system...\n"
yum update -y

echo -e "Downloading and installing PostgreSQL RPM...\n"
yum localinstall https://download.postgresql.org/pub/repos/yum/9.4/redhat/rhel-6-x86_64/pgdg-centos94-9.4-3.noarch.rpm -y

echo -e "Installing Epel-Release RPM...\n"
rpm -Uvh http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm

echo -e "Installing software...\n"
yum install postgresql94-server postgresql94-plpython postgresql94-devel postgis2_94 postgis2_94-devel python-virtualenv python-pip nodejs nodejs-devel npm git mod_wsgi tmux gcc -y

echo -e "Initialize database and starting postgres...\n"
service postgresql-9.4 initdb 
service postgresql-9.4 start

echo -e "Taking ownership of /usr/local/src with non-root account...\n"
chown $username  /usr/local/src

echo -e "Changing to $username...\n"
su $username -c > /dev/null 2>&1

cd /usr/local/src
mkdir geoq
virtualenv ./geoq
cd geoq
source bin/activate
git clone https://github.com/ngageoint/geoq.git
cd geoq

sudo -u postgres psql << EOF # password might be needed here
create role geoq login password 'geoq';
create database geoq with owner geoq;
\c geoq
create extension postgis;
create extension postgis_topology;
EOF

export PATH=$PATH:/usr/pgsql-9.4/bin
pip install paver packaging appdirs
sed -ie 's/six==1.4.1/six>=1.6.0/g' /usr/local/src/geoq/geoq/geoq/requirements.txt
paver install_dependencies

echo -e "Becoming root user again...\n"
su -c > /dev/null 2>&1

sed -ie '/#/!s/ident/md5/g' /var/lib/pgsql/9.4/data/pg_hba.conf

echo -e "Restarting PostgreSQL...\n"
service postgresql-9.4 restart

echo -e "Becoming user again...\n"
su $username -c > /dev/null 2>&1 
paver sync
paver install_dev_fixtures
sudo npm install -g less
cat << EOF > geoq/local_settings.py
STATIC_URL_FOLDER = '/static'
STATIC_ROOT = '{0}{1}'.format('/var/www/html', STATIC_URL_FOLDER)
EOF
sudo chown centos /var/www/html # need to take ownership of /var/www/html and what's inside
python manage.py collectstatic # can this be automated with a -y? it prompts for a yes / no
python manage.py createsuperuser
paver start_django
