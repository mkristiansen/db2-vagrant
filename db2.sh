#!/bin/bash

# This is needed because we must sync 64 bit packages to 32 bit ones
echo "DB2.sh: Running yum update"
yum update -y

echo "DB2.sh: Running yum install with 32-bit compatibility libraries"
yum install -y wget nfs-utils libaio* ksh compat-libstdc++* libstdc++* numactl.x86_64 pam.i686 install libstdc++.i686 kernel-develop

echo "DB2.sh: Running yum install with 32-bit compatibility libraries"
cp /vagrant/v10.5_linuxx64_expc.tar.gz /tmp
cd /tmp

tar -xvf v10.5_linuxx64_expc.tar.gz

rm -f v10.5_linuxx64_expc.tar.gz

# Launch the installer
echo "DB2.sh: Running DB2 installer (db2_install)"
/tmp/expc/db2_install -n -b /opt/ibm/db2/V10.5  -p expc

rm -r -f /tmp/expc/

# Groups
echo "DB2.sh: Creating required groups"
/usr/sbin/groupadd -g 510 db2grp1
/usr/sbin/groupadd -g 511 db2fgrp1
/usr/sbin/groupadd -g 999 db2iadm1
/usr/sbin/groupadd -g 998 db2fadm1
/usr/sbin/groupadd -g 997 dasadm1
/usr/sbin/groupadd -g 1000 db2dev


# Users
echo "DB2.sh: Creating required users"
/usr/sbin/useradd -p db2inst1 -g db2grp1 -m -d /home/db2inst1 db2inst1
/usr/sbin/useradd -p db2fenc1 -g db2fgrp1 -m -d /home/db2fenc1 db2fenc1
/usr/sbin/useradd -p dasusr1 -g dasadm1 -m -d /home/dasusr1 dasusr1
/usr/sbin/useradd -p db2dev -g db2dev -m -d /home/db2user db2user

# Instance
echo "DB2.sh: Creating the Database Instance"
/opt/ibm/db2/V10.5/instance/db2icrt -a SERVER -p 50000 -u db2fenc1 db2inst1

# Das user
/opt/ibm/db2/V10.5/instance/dascrt -u dasusr1

# Remote administration
echo "DB2.sh: Add DB2 to /etc/services"
echo 'ibm-db2 523/tcp # IBM DB2 DAS' >> /etc/services
echo 'ibm-db2 523/udp # IBM DB2 DAS' >> /etc/services
echo 'db2c_db2inst1 50000/tcp # IBM DB2 instance - db2inst1' >> /etc/services

echo "DB2.sh: Set configuration options"
sudo -i -u db2inst1 /opt/ibm/db2/V10.5/bin/db2 update dbm cfg using SVCENAME db2c_db2inst1
sudo -i -u db2inst1 /home/db2inst1/sqllib/adm/db2set DB2COMM=tcpip
sudo -i -u db2inst1 /home/db2inst1/sqllib/adm/db2set DB2_EXTENDED_OPTIMIZATION=ON
sudo -i -u db2inst1 /home/db2inst1/sqllib/adm/db2set DB2_DISABLE_FLUSH_LOG=ON
sudo -i -u db2inst1 /home/db2inst1/sqllib/adm/db2set AUTOSTART=YES
sudo -i -u db2inst1 /home/db2inst1/sqllib/adm/db2set DB2_HASH_JOIN=Y
sudo -i -u db2inst1 /home/db2inst1/sqllib/adm/db2set DB2_PARALLEL_IO=*
sudo -i -u db2inst1 /home/db2inst1/sqllib/adm/db2set DB2CODEPAGE=1208
sudo -i -u db2inst1 /home/db2inst1/sqllib/adm/db2set DB2_COMPATIBILITY_VECTOR=3F
sudo -i -u db2inst1 /opt/ibm/db2/V10.5/bin/db2 update dbm cfg using INDEXREC ACCESS

# Start the instance
echo "DB2.sh: Start the Database Instance"
sudo -i -u db2inst1 /home/db2inst1/sqllib/adm/db2start

# Start the administration server
echo "DB2.sh: Start the administration server"
sudo -i -u dasusr1 /home/dasusr1/das/bin/db2admin stop
sudo -i -u dasusr1 /home/dasusr1/das/bin/db2admin start

# Autostart
echo "DB2.sh: Configure DB2 to autostart when OS is started"
su - db2inst1
/home/db2inst1/sqllib/bin/db2iauto -on db2inst1
exit

# Admin interface autostart
echo "DB2.sh: Create administartion server startup script; /home/dasusr1/script/startadmin.sh"
mkdir /home/dasusr1/script
touch /home/dasusr1/script/startadmin.sh
echo '#!/bin/sh' >> /home/dasusr1/script/startadmin.sh
echo '# The following three lines have been added by UDB DB2.' >> /home/dasusr1/script/startadmin.sh
echo 'if [ -f /home/dasusr1/das/dasprofile ]; then' >> /home/dasusr1/script/startadmin.sh
echo '. /home/dasusr1/das/dasprofile' >> /home/dasusr1/script/startadmin.sh
echo 'fi' >> /home/dasusr1/script/startadmin.sh
echo 'db2admin start' >> /home/dasusr1/script/startadmin.sh

chown dasusr1:dasadm1 -R /home/dasusr1/script
chmod 777 /home/dasusr1/script/startadmin.sh

# Finalizing
echo "DB2.sh: Set various helper options in profiles"
echo '# Something useful for DB2' >> /home/db2inst1/.bashrc
echo 'export PATH=/home/db2inst1/scripts:$PATH' >> /home/db2inst1/.bashrc
echo 'export DB2CODEPAGE=1208' >> /home/db2inst1/.bashrc

echo 'export DB2CODEPAGE=1208' >> /home/db2inst1/sqllib/db2profile

echo 'DB2INSTANCE=db2inst1' >> /etc/profile
echo 'export DB2INSTANCE' >> /etc/profile
echo 'INSTHOME=/home/db2inst1' >> /etc/profile
echo 'export DB2CODEPAGE=1208' >> /etc/profile

echo "DB2.sh: All done!!"