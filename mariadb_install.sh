#!/bin/bash
 
# Author: cadi
# project: 
# des: mariadb installation

#请把脚本和mariadb二进制安装文件放在ROOT目录下
#安装目录/opt/mysql
#数据存放目录/data/mysql

MariadbV=mariadb-galera-10.0.34
dbVersion=mariadb-10.0.34
#设置CPU编译效率
UJ=`awk '/processor/{i++}END{print i}' /proc/cpuinfo`

if [[ "$(whoami)" != "root" ]]; then
  
    echo "please run this script as root ." >&2
    exit 1
fi
if [ ! -f "/root/mariadb_install_galera/$MariadbV.tar.gz" ]; then
echo Can not find a file.
exit;
fi


#解压
cd /root/mariadb_install_galera
tar zxvf $MariadbV.tar.gz

#卸载自带模块
rpm -e mariadb-libs-5.5.56-2.el7.x86_64 --nodeps
#删除自带配置
rm -rf /etc/my.cnf /etc/my.cnf.d/
#创建文件
touch /etc/my.cnf
mkdir /etc/my.cnf.d

#安装相关支持库
yum -y install libaio libaio-devel bison bison-devel zlib-devel openssl openssl-devel ncurses ncurses-devel libcurl-devel libarchive-devel boost boost-devel lsof wget gcc-c++ make cmake perl kernel-headers kernel-devel  pcre-devel

#安装同步软件rsync
yum -y install rsync
#安装galera
cd /root/mariadb_install_galera
rpm -ivh boost-program-options-1.53.0-27.el7.x86_64.rpm
rpm -ivh jemalloc-3.6.0-1.el7.x86_64.rpm
rpm -ivh jemalloc-devel-3.6.0-1.el7.x86_64.rpm
rpm -ivh galera-25.3.22-1.rhel7.el7.centos.x86_64.rpm


#创建用户和用户组
groupadd -r mysql
useradd -r -g mysql -s /sbin/nologin -d /opt/mysql -M mysql

#创建路径
mkdir -p /usr/local/mysql
mkdir -p /data/mysql

#授权
chown -R mysql:mysql /data
chown -R mysql:mysql /usr/local/mysql

#编译安装
cd /root/mariadb_install_galera/$dbVersion
 

cmake . -DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
-DMYSQL_DATADIR=/data/mysql -DSYSCONFDIR=/etc \
-DWITH_SSL=system -DWITH_INNOBASE_STORAGE_ENGINE=1 \
-DWITH_ARCHIVE_STORAGE_ENGINE=1 -DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
-DWITH_SPHINX_STORAGE_ENGINE=1 -DWITH_ARIA_STORAGE_ENGINE=1 \
-DWITH_XTRADB_STORAGE_ENGINE=1 -DWITH_PARTITION_STORAGE_ENGINE=1 \
-DWITH_FEDERATEDX_STORAGE_ENGINE=1 -DWITH_MYISAM_STORAGE_ENGINE=1 \
-DWITH_PERFSCHEMA_STORAGE_ENGINE=1 -DWITH_EXTRA_CHARSETS=all \
-DWITH_EMBEDDED_SERVER=1 -DWITH_READLINE=1 -DWITH_ZLIB=system \
-DWITH_LIBWRAP=0 -DEXTRA_CHARSETS=all -DENABLED_LOCAL_INFILE=1 \
-DMYSQL_UNIX_ADDR=/tmp/mysql.sock -DDEFAULT_CHARSET=utf8 \
-DDEFAULT_COLLATION=utf8_general_ci \
-DWITH_WSREP=1 -DWITH_INNODB_DISALLOW_WRITES=1 && make -j$UJ && make install

#拷贝文件
cp /usr/local/mysql/support-files/mysql.server /etc/rc.d/init.d/mysqld

#配置mysql
cat > /etc/my.cnf << EOF
#mariadb configuration for 16G memory
[client-server]
!includedir /etc/my.cnf.d
EOF

cp /root/mariadb_install_galera/conf/* /etc/my.cnf.d/


#初始化配置
cd /usr/local/mysql/
scripts/mysql_install_db --user=mysql --datadir=/data/mysql > /dev/null &&


#配置变量
touch /etc/profile.d/mysql.sh
echo "export PATH=$PATH:/usr/local/mysql/bin/" > /etc/profile.d/mysql.sh
chmod 0777 /etc/profile.d/mysql.sh
source /etc/profile.d/mysql.sh

#启动mysql服务
#/etc/rc.d/init.d/mysqld start
#source /etc/profile.d/mysql.sh

#初始化mysql
#ln -s /data/mysql/mysql.sock /tmp/mysql.sock
#mysql_secure_installation
