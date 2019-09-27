#!/bin/bash
#本脚本搭建lnmp和wordpress,方便大家在同一平台编辑文档.
#安装源码编译所需的依赖包.
yum -y install gcc openssl-devel pcre-devel  
#为nginx创建用户
useradd -s /sbin/nologin  nginx
cd lnmp_soft
tar -xvf nginx-1.12.2.tar.gz
cd nginx-1.12.2
#编译并安装nginx
./configure   --user=nginx   --group=nginx --with-http_ssl_module  --with-http_stub_status_module
make
make install
#启动nginx服务
/usr/local/nginx/sbin/nginx
#安装lnmp所需要的包
yum -y install   mariadb   mariadb-server   mariadb-devel
yum -y install   php        php-mysql        php-fpm
systemctl start   mariadb
systemctl enable  mariadb
systemctl start  php-fpm
systemctl enable php-fpm
#编辑/usr/lib/systemd/system/nginx.service文件,让nginxg支持systemctl启动.
echo '[Unit]
Description=The Nginx HTTP Server
After=network.target remote-fs.target nss-lookup.target
[Service]
Type=forking
ExecStart=/usr/local/nginx/sbin/nginx
ExecReload=/usr/local/nginx/sbin/nginx -s reload
ExecStop=/bin/kill -s QUIT ${MAINPID}
[Install]
WantedBy=multi-user.target'  > /usr/lib/systemd/system/nginx.service
#修改nginx配置文件,支持动静分离
sed -ri "65,71s/#//" /usr/local/nginx/conf/nginx.conf
sed -ri "s/fastcgi_params/fastcgi.conf/" /usr/local/nginx/conf/nginx.conf
sed -ri 's/(index.html)/index.php \1/' /usr/local/nginx/conf/nginx.conf
sed -ri '/SCRIPT_FILENAME/d' /usr/local/nginx/conf/nginx.conf
#设置nginx开机自启动
systemctl restart nginx
systemctl enable nginx
#创建数据库,添加用户
mysql  <<EOF
create database wordpress character set utf8mb4;
grant all on wordpress.* to wordpress@'localhost' identified by 'wordpress';
grant all on wordpress.* to wordpress@'192.168.2.11' identified by 'wordpress';
flush privileges;
EOF
#准备好wordpress模板,把模板内容拷贝到/usr/local/nginx/html/
cd /root
yum install -y unzip
unzip wordpress.zip
cd wordpress
tar -xf wordpress-5.0.3-zh_CN.tar.gz
cp -r  wordpress/*  /usr/local/nginx/html/
chown -R apache.apache  /usr/local/nginx/html/

