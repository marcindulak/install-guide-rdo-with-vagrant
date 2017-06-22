# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'digest/md5'

OPENSTACK_RELEASE = 'ocata'

LABEL_CRUDINI = '  # the line below was added by crudini'

ENV['VAGRANT_DEFAULT_PROVIDER'] = 'libvirt'

# openstack services may report OK status, but are not fully functional - give them time
SLEEP30 = 'sleep 30'

# https://docs.openstack.org/ocata/install-guide-rdo/launch-instance-networks-provider.html
PROVIDER_INTERFACE_NAME = 'eth2'
START_IP_ADDRESS = '203.0.113.101'
END_IP_ADDRESS = '203.0.113.250'
DNS_RESOLVER = '192.168.122.1'
PROVIDER_NETWORK_GATEWAY = '203.0.113.1'
PROVIDER_NETWORK_CIDR = '203.0.113.0/24'
# https://docs.openstack.org/ocata/install-guide-rdo/launch-instance-networks-selfservice.html
SELFSERVICE_NETWORK_GATEWAY = '172.16.1.1'
SELFSERVICE_NETWORK_CIDR = '172.16.1.0/24'

# https://docs.openstack.org/ocata/install-guide-rdo/overview.html#example-architecture
nodes = ['controller', 'compute1', 'block1']  # limit the setup to those nodes only
arch = {
  'controller' => {
    'hostname' => 'controller',
    'IP address' => '10.0.0.11',
    'Network mask' => '24',
    'Default gateway' => '10.0.0.1',
    'Hardware Requirements' => {
      'CPU' => 1,
      'RAM' => 4096,
      'NIC' => 2},
  },
  'compute1' => {
    'hostname' => 'compute1',
    'IP address' => '10.0.0.31',
    'Network mask' => '24',
    'Default gateway' => '10.0.0.1',
    'Hardware Requirements' => {
      'CPU' => 2,
      'RAM' => 1024,
      'NIC' => 2},
  },
  'compute2' => {
    'hostname' => 'compute2',
    'IP address' => '10.0.0.32',
    'Network mask' => '24',
    'Default gateway' => '10.0.0.1',
    'Hardware Requirements' => {
      'CPU' => 2,
      'RAM' => 1024,
      'NIC' => 2},
  },
  'block1' => {
    'hostname' => 'block1',
    'IP address' => '10.0.0.41',
    'Network mask' => '24',
    'Default gateway' => '10.0.0.1',
    'Hardware Requirements' => {
      'CPU' => 1,
      'RAM' => 512,
      'NIC' => 1},
  },
  'object1' => {
    'hostname' => 'object1',
    'IP address' => '10.0.0.51',
    'Network mask' => '24',
    'Default gateway' => '10.0.0.1',
    'Hardware Requirements' => {
      'CPU' => 1,
      'RAM' => 512,
      'NIC' => 1},
  },
  'object2' => {
    'hostname' => 'object2',
    'IP address' => '10.0.0.52',
    'Network mask' => '24',
    'Default gateway' => '10.0.0.1',
    'Hardware Requirements' => {
      'CPU' => 1,
      'RAM' => 512,
      'NIC' => 1},
  },
}

# https://docs.openstack.org/ocata/install-guide-rdo/environment-security.html
Passwords = {
  'DB_PASSWORD'     => 'DBpass',  # Root password for the database
  'ADMIN_PASS'      => 'ADMINpass',  # Password of user admin
  'CINDER_DBPASS'   => 'CINDERpass',  # Database password for the Block Storage service
  'CINDER_PASS'     => 'CINDERpass',  # Password of Block Storage service user cinder
  'DASH_DBPASS'     => 'DASHpass',  # Database password for the Dashboard
  'DEMO_PASS'       => 'DEMOpass',  # Password of user demo
  'GLANCE_DBPASS'   => 'GLANCEpass',  # Database password for Image service
  'GLANCE_PASS'     => 'GLANCEpass',  # Password of Image service user glance
  'KEYSTONE_DBPASS' => 'KEYSTONEpass',  # Database password of Identity service
  'METADATA_SECRET' => 'METADATAsecret',  # Secret for the metadata proxy
  'NEUTRON_DBPASS'  => 'NEUTRONpass',  # Database password for the Networking service
  'NEUTRON_PASS'    => 'NEUTRONpass',  # Password of Networking service user neutron
  'NOVA_DBPASS'     => 'NOVApass',  # Database password for Compute service
  'NOVA_PASS'       => 'NOVApass',  # Password of Compute service user nova
  'PLACEMENT_PASS'  => 'PLACEMENTpass',  # Password of the Placement service user placement
  'RABBIT_PASS'     => 'RABBITpass',  # Password of user guest of RabbitMQ
}

Vagrant.configure(2) do |config|
  nodes.each do |node|
    config.vm.define arch[node]['hostname'] do |machine|
      machine.vm.box = 'centos/7'
      machine.vm.box_url = machine.vm.box
      machine.vm.provider 'libvirt' do |p|
        p.cpus = arch[node]['Hardware Requirements']['CPU']
        p.memory = arch[node]['Hardware Requirements']['RAM']
        p.nested = true
        # https://github.com/vagrant-libvirt/vagrant-libvirt: management_network_address defaults to 192.168.121.0/24
        p.management_network_name = 'vagrant-install-guide-rdo'
        p.management_network_address = '192.168.122.0/24'
        # https://github.com/vagrant-libvirt/vagrant-libvirt/issues/402
        p.management_network_mode = 'nat'
        # don't prefix VM names with the PWD
        # https://github.com/vagrant-libvirt/vagrant-libvirt/issues/289
        p.default_prefix = ''
        if node.start_with?('block')
          p.storage :file, :size => '2G', :path => arch[node]['hostname'] + '_sdb.img', :allow_existing => true, :shareable => false, :type => 'raw'
        end
      end
      # configure additional network interfaces (eth0 is used by Vagrant for management)
      (1..(arch[node]['Hardware Requirements']['NIC'])).to_a.each do |interface|
        if interface == 1
          ip = arch[node]['IP address']  # first interface (eth1) settings are defined
          libvirt__network_name = 'vagrant-install-guide-rdo-selfservice'
        else
          ip = '203.0.113.' + arch[node]['IP address'].split('.')[-1]  # use dummy network for the remaining interfaces
          libvirt__network_name = 'vagrant-install-guide-rdo-provider'
        end
        # generate unique MAC address for this ip + interface
        mac = '08:00:27:' + Digest::MD5.hexdigest(ip + interface.to_s).slice(0, 6).scan(/.{1,2}/).join(':')
        # netmask from cidr
        netmask = IPAddr.new("255.255.255.255").mask(arch[node]['Network mask']).to_s
        # :auto_config => 'false' configures the specific mac and sets a random ip in the network defined by ip and netmask
        machine.vm.network :private_network, :auto_config => 'false', :libvirt__network_name => libvirt__network_name, :ip => ip, :libvirt__netmask => netmask, :mac => mac
      end
      # forward horizon port to be accessible from outside the Vagrant host
      if arch[node]['hostname'] == 'controller'
        machine.vm.network "forwarded_port", adapter: 'eth1', host_ip: '*', guest: 80, host: 8080
      end
    end
  end
  # disable IPv6 on Linux
  $linux_disable_ipv6 = <<SCRIPT
set -x
sysctl -w net.ipv6.conf.default.disable_ipv6=1
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.lo.disable_ipv6=1
SCRIPT
  # setenforce 0
  $setenforce_0 = <<SCRIPT
set -x
if test `getenforce` = 'Enforcing'; then setenforce 0; fi
sed -Ei 's/^SELINUX=.*/SELINUX=Permissive/' /etc/selinux/config
SCRIPT
  # setenforce 1
  $setenforce_1 = <<SCRIPT
set -x
if test `getenforce` != 'Enforcing'; then setenforce 1; fi
sed -Ei 's/^SELINUX=.*/SELINUX=Enforcing/' /etc/selinux/config
SCRIPT
  # common settings on all machines
  $etc_hosts = <<SCRIPT
echo "$*" >> /etc/hosts
SCRIPT
  # configure the second and further Vagrant interfaces
  $ifcfg = <<SCRIPT
DEVICE=$1
TYPE=$2
IPADDR=$3
NETMASK=$4
HWADDR=$5
set -x
cat <<END > /etc/sysconfig/network-scripts/ifcfg-$DEVICE
NM_CONTROLLED=no
BOOTPROTO=none
ONBOOT=yes
IPADDR=$IPADDR
NETMASK=$NETMASK
DEVICE=$DEVICE
PEERDNS=no
TYPE=$TYPE
HWADDR=$HWADDR
END
ARPCHECK=no /sbin/ifup $DEVICE 2> /dev/null
restorecon -v /etc/sysconfig/network-scripts/ifcfg-$DEVICE
chown root.root /etc/sysconfig/network-scripts/ifcfg-$DEVICE
chmod go+r /etc/sysconfig/network-scripts/ifcfg-$DEVICE
SCRIPT
  # Create and edit the /etc/my.cnf.d/openstack.cnf file
  $etc_my_cnf_d_openstack_cnf = <<SCRIPT
BIND_ADDRESS=$1
set -x
cat <<END > /etc/my.cnf.d/openstack.cnf
[mysqld]
bind-address = $BIND_ADDRESS

default-storage-engine = innodb
innodb_file_per_table = on
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8
END
SCRIPT
  # Secure the database service
  $mysql_secure_installation = <<SCRIPT
ROOT_PASSWORD=$1
if test -f /root/.mysql_secret; then
CURRENT_ROOT_PASSWORD=`cat /root/.mysql_secret | cut -d':' -f4 | tr -d ' '`
else
CURRENT_ROOT_PASSWORD=''
fi
touch /root/mysql_secure_installation
chmod go-rwx /root/mysql_secure_installation
cat <<END >> /root/mysql_secure_installation
#!/usr/bin/expect --
spawn mysql_secure_installation

expect "Enter current password for root (enter for none):"
send "$CURRENT_ROOT_PASSWORD\r"

expect "Set root password?"
send "y\r"

expect "New password:"
send "$ROOT_PASSWORD\r"

expect "Re-enter new password:"
send "$ROOT_PASSWORD\r"

expect "Remove anonymous users?"
send "y\r"

expect "Disallow root login remotely?"
send "y\r"

expect "Remove test database and access to it?"
send "y\r"

expect "Reload privilege tables now?"
send "y\r"

puts "Ended expect script."
END
SCRIPT
  $crudini_set = <<SCRIPT
config_file=$1
section=$2
parameter=$3
value=$4
label_crudini=$5
set -x
value_escaped=`echo $value | sed 's#/#\\\\\\/#g'`
if test -z $section;
then
crudini --set "$config_file" '' "$parameter" "$value"
else
crudini --set "$config_file" "$section" "$parameter" "$value"
fi
sed -i "/$parameter.*$value_escaped/i$label_crudini" "$config_file"
SCRIPT
  # https://docs.openstack.org/ocata/install-guide-rdo/keystone-openrc.html
  $openrc = <<SCRIPT
OS_PROJECT_NAME=$1
OS_USERNAME=$2
OS_PASSWORD=$3
OS_AUTH_URL=$4
set -x
cat <<END > /root/${OS_USERNAME}-openrc
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=$OS_PROJECT_NAME
export OS_USERNAME=$OS_USERNAME
export OS_PASSWORD=$OS_PASSWORD
export OS_AUTH_URL=$OS_AUTH_URL
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
END
setfacl -m u:vagrant:r /root/${OS_USERNAME}-openrc
setfacl -m u:vagrant:x /root
SCRIPT
  $create_database = <<SCRIPT
MYSQL_ROOT_PASSWORD=$1
DATABASE=$2
USER=$3
PASSWORD=$4
set -x
echo "CREATE DATABASE $DATABASE;" | mysql -uroot -p$MYSQL_ROOT_PASSWORD
echo "GRANT ALL PRIVILEGES ON $DATABASE.* TO '$USER'@'localhost' IDENTIFIED BY '$PASSWORD';" | mysql -uroot -p$MYSQL_ROOT_PASSWORD
echo "GRANT ALL PRIVILEGES ON $DATABASE.* TO '$USER'@'%' IDENTIFIED BY '$PASSWORD';" | mysql -uroot -p$MYSQL_ROOT_PASSWORD
# https://bugs.launchpad.net/openstack-manuals/+bug/1698455
echo "GRANT ALL PRIVILEGES ON $DATABASE.* TO '$USER'@'controller' IDENTIFIED BY '$PASSWORD';" | mysql -uroot -p$MYSQL_ROOT_PASSWORD
echo "SHOW GRANTS FOR $USER;" | mysql -uroot -p$MYSQL_ROOT_PASSWORD
echo 'SELECT HOST, USER from user\\G' | mysql -uroot -p$MYSQL_ROOT_PASSWORD mysql
SCRIPT
  $bugzilla1430540 = <<SCRIPT
set -x
cat <<END > /etc/httpd/conf.d/00-nova-placement-api.conf.bugzilla1430540
<Directory /usr/bin>
   <IfVersion >= 2.4>
      Require all granted
   </IfVersion>
   <IfVersion < 2.4>
      Order allow,deny
      Allow from all
   </IfVersion>
</Directory>
END
chown apache.apache /etc/httpd/conf.d/00-nova-placement-api.conf.bugzilla1430540
sed -i '/nova-placement-api.log/r /etc/httpd/conf.d/00-nova-placement-api.conf.bugzilla1430540' /etc/httpd/conf.d/00-nova-placement-api.conf
SCRIPT
  # perform the common configuration for all nodes
  nodes.each do |node|
    config.vm.define arch[node]['hostname'] do |machine|
      machine.vm.provision :shell, :inline => 'hostname ' + arch[node]['hostname'], run: 'always'
      machine.vm.provision :shell, :inline => 'hostnamectl set-hostname ' + arch[node]['hostname']
      machine.vm.provision :shell, :inline => 'systemctl stop firewalld'
      machine.vm.provision :shell, :inline => 'systemctl disable firewalld'
      # reconfigure settings written by vagrant-libvirt for the first interface (eth1)
      # https://docs.openstack.org/ocata/install-guide-rdo/environment-networking-compute.html#configure-network-interfaces
      if true
      machine.vm.provision 'shell' do |s|
        s.inline = $ifcfg
        # DEVICE, TYPE, IPADDR, NETMASK, HWADDR
        s.args   = ['eth1', 'Ethernet', arch[node]['IP address'],
                    IPAddr.new("255.255.255.255").mask(arch[node]['Network mask']).to_s,
                    '08:00:27:' + Digest::MD5.hexdigest(arch[node]['IP address'] + '1').slice(0, 6).scan(/.{1,2}/).join(':')]
      end
      machine.vm.provision :shell, :inline => 'systemctl stop NetworkManager'
      machine.vm.provision :shell, :inline => 'systemctl disable NetworkManager'
      # https://docs.openstack.org/ocata/install-guide-rdo/environment-packages.html
      machine.vm.provision :shell, :inline => 'yum -y install centos-release-openstack-' + OPENSTACK_RELEASE
      machine.vm.provision :shell, :inline => 'yum -y install crudini'
      machine.vm.provision :shell, :inline => 'crudini --del /etc/sysconfig/network-scripts/ifcfg-eth0 "" NM_CONTROLLED'
      (2..(arch[node]['Hardware Requirements']['NIC'])).to_a.each do |interface|
        # the provider interface (eth2) uses a special configuration without an IP address assigned to it
        # remove IP address and disable NetworkManager
        # it seems like if I remove the IP address here the unable to ping the created provider router IP
        #machine.vm.provision :shell, :inline => 'crudini --del /etc/sysconfig/network-scripts/ifcfg-eth' + interface.to_s + ' "" IPADDR'
        #machine.vm.provision :shell, :inline => 'crudini --del /etc/sysconfig/network-scripts/ifcfg-eth' + interface.to_s + ' "" NETMASK'
        machine.vm.provision :shell, :inline => 'crudini --set /etc/sysconfig/network-scripts/ifcfg-eth' + interface.to_s + ' "" NM_CONTROLLED no'
        machine.vm.provision :shell, :inline => 'ifup eth' + interface.to_s, run: 'always'
      end
      machine.vm.provision :shell, :inline => 'ifup eth1', run: 'always'
      # restarting network fixes RTNETLINK answers: File exists
      machine.vm.provision :shell, :inline => 'systemctl enable network'
      machine.vm.provision :shell, :inline => 'systemctl restart network'
      end
      machine.vm.provision :shell, :inline => $linux_disable_ipv6, run: 'always'
      # entries for all nodes in /etc/hosts
      # https://docs.openstack.org/ocata/install-guide-rdo/environment-networking-compute.html#configure-name-resolution
      arch.keys.sort.each do |n|
        machine.vm.provision 'shell' do |s|
          s.inline = $etc_hosts
          s.args   = [arch[n]['IP address'], arch[n]['hostname']]
        end
      end
      # install and enable chrony
      # https://docs.openstack.org/ocata/install-guide-rdo/environment-ntp.html
      machine.vm.provision :shell, :inline => 'yum -y install chrony'
      machine.vm.provision :shell, :inline => 'systemctl enable chronyd.service'
      machine.vm.provision :shell, :inline => 'systemctl start chronyd.service'
      # https://docs.openstack.org/ocata/install-guide-rdo/environment-packages.html
      machine.vm.provision :shell, :inline => 'yum clean all'
      machine.vm.provision :shell, :inline => 'yum -y upgrade'
      #machine.vm.provision :shell, :inline => 'yum -y install centos-release-openstack-' + OPENSTACK_RELEASE
      machine.vm.provision :shell, :inline => 'yum -y install python-openstackclient'
      machine.vm.provision :shell, :inline => 'yum -y install openstack-selinux'
      machine.vm.provision :shell, :inline => $setenforce_1
      machine.vm.provision :shell, :inline => 'yum -y install jq'
      machine.vm.provision :shell, :inline => 'yum -y install crudini'
    end
  end
  # the openstack configuration needs to be performed in the order
  config.vm.define 'controller' do |machine|
    node = 'controller'
    # https://docs.openstack.org/ocata/install-guide-rdo/environment-sql-database.html
    machine.vm.provision :shell, :inline => 'yum -y install mariadb mariadb-server python2-PyMySQL'
    machine.vm.provision :shell, :inline => 'yum -y install expect'
    machine.vm.provision :shell, :inline => 'systemctl enable mariadb.service'
    machine.vm.provision :shell, :inline => 'systemctl start mariadb.service'
    machine.vm.provision 'shell' do |s|
      s.inline = $mysql_secure_installation
      s.args   = [Passwords['DB_PASSWORD']]
    end
    machine.vm.provision :shell, :inline => 'expect /root/mysql_secure_installation'
    # https://docs.openstack.org/ocata/install-guide-rdo/environment-messaging.html
    machine.vm.provision :shell, :inline => 'yum -y install rabbitmq-server'
    machine.vm.provision :shell, :inline => 'systemctl enable rabbitmq-server.service'
    machine.vm.provision :shell, :inline => 'systemctl start rabbitmq-server.service'
    machine.vm.provision :shell, :inline => 'rabbitmqctl add_user openstack ' + Passwords['RABBIT_PASS']
    machine.vm.provision :shell, :inline => 'rabbitmqctl set_permissions openstack ".*" ".*" ".*"'
    # https://docs.openstack.org/ocata/install-guide-rdo/environment-memcached.html
    machine.vm.provision :shell, :inline => 'yum -y install memcached python-memcached'
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/sysconfig/memcached',
                  '', 'OPTIONS', '"-l 127.0.0.1,::1,controller"', LABEL_CRUDINI]
    end
    machine.vm.provision :shell, :inline => 'systemctl enable memcached.service'
    machine.vm.provision :shell, :inline => 'systemctl start memcached.service'
    # https://docs.openstack.org/ocata/install-guide-rdo/keystone-install.html
    machine.vm.provision 'shell' do |s|
      s.inline = $create_database
      # MYSQL_ROOT_PASSWORD, DATABASE, USER, PASSWORD
      s.args   = [Passwords['DB_PASSWORD'], 'keystone', 'keystone', Passwords['KEYSTONE_DBPASS']]
    end
    machine.vm.provision :shell, :inline => 'yum -y install openstack-keystone httpd mod_wsgi'
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/keystone/keystone.conf',
                  'database', 'connection', '"mysql+pymysql://keystone:' + Passwords['KEYSTONE_DBPASS'] + '@controller/keystone"', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/keystone/keystone.conf',
                  'token', 'provider', 'fernet', LABEL_CRUDINI]
    end
    machine.vm.provision :shell, :inline => 'su - keystone -s /bin/sh -c "keystone-manage db_sync" keystone'
    machine.vm.provision :shell, :inline => 'keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone'
    machine.vm.provision :shell, :inline => 'keystone-manage credential_setup --keystone-user keystone --keystone-group keystone'
    machine.vm.provision :shell, :inline => 'keystone-manage bootstrap --bootstrap-password ' + Passwords['ADMIN_PASS'] + '\
                                             --bootstrap-admin-url http://controller:35357/v3/ \
                                             --bootstrap-internal-url http://controller:5000/v3/ \
                                             --bootstrap-public-url http://controller:5000/v3/ \
                                             --bootstrap-region-id RegionOne'
    machine.vm.provision :shell, :inline => 'sed -i "s/#ServerName www.example.com:80/ServerName controller/" /etc/httpd/conf/httpd.conf'
    machine.vm.provision :shell, :inline => 'ln -s /usr/share/keystone/wsgi-keystone.conf /etc/httpd/conf.d/'
    machine.vm.provision :shell, :inline => 'systemctl enable httpd.service'
    machine.vm.provision :shell, :inline => 'systemctl start httpd.service'
    # https://docs.openstack.org/ocata/install-guide-rdo/keystone-openrc.html
    machine.vm.provision 'shell' do |s|
      s.inline = $openrc
      # OS_PROJECT_NAME, OS_USERNAME, OS_PASSWORD, OS_AUTH_URL
      s.args   = ['admin', 'admin', Passwords['ADMIN_PASS'], 'http://controller:35357/v3']
    end
    # https://docs.openstack.org/ocata/install-guide-rdo/keystone-users.html
    machine.vm.provision 'shell' do |s|
      s.inline = $openrc
      # OS_PROJECT_NAME, OS_USERNAME, OS_PASSWORD, OS_AUTH_URL
      s.args   = ['demo', 'demo', Passwords['DEMO_PASS'], 'http://controller:5000/v3']
    end
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& openstack project create --domain default --description "Service Project" service'
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& openstack project create --domain default --description "Demo Project" demo'
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& openstack user create --domain default --password ' + Passwords['DEMO_PASS'] + ' demo'
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& openstack role create user'
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& openstack role add --project demo --user demo user'
    # https://docs.openstack.org/ocata/install-guide-rdo/keystone-verify.html
    machine.vm.provision :shell, :inline => 'sed -i "s/ admin_token_auth / /" /etc/keystone/keystone-paste.ini'
    # https://docs.openstack.org/ocata/install-guide-rdo/keystone-openrc.html
    #machine.vm.provision :shell, :inline => 'sed -i "/OS_AUTH_URL/d" /root/admin-openrc'  # MDTMP - let's keep it
    #machine.vm.provision :shell, :inline => 'sed -i "/OS_PASSWORD/d" /root/admin-openrc'  # MDTMP - let's keep it
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& openstack --os-auth-url http://controller:35357/v3 \
                                            --os-project-domain-name default --os-user-domain-name default \
                                            --os-project-name admin --os-username admin token issue'
    #machine.vm.provision :shell, :inline => 'sed -i "/OS_AUTH_URL/d" /root/demo-openrc'  # MDTMP - let's keep it
    #machine.vm.provision :shell, :inline => 'sed -i "/OS_PASSWORD/d" /root/demo-openrc'  # MDTMP - let's keep it
    machine.vm.provision :shell, :inline => 'source /root/demo-openrc&& openstack --os-auth-url http://controller:5000/v3 \
                                            --os-project-domain-name default --os-user-domain-name default \
                                            --os-project-name demo --os-username demo token issue'
    # https://docs.openstack.org/ocata/install-guide-rdo/glance-install.html
    machine.vm.provision 'shell' do |s|
      s.inline = $create_database
      # MYSQL_ROOT_PASSWORD, DATABASE, USER, PASSWORD
      s.args   = [Passwords['DB_PASSWORD'], 'glance', 'glance', Passwords['GLANCE_DBPASS']]
    end
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& openstack user create --domain default --password ' + Passwords['GLANCE_PASS'] + ' glance'
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& openstack role add --project service --user glance admin'
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& openstack service create --name glance --description "OpenStack Image" image'
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& openstack endpoint create --region RegionOne image public http://controller:9292'
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& openstack endpoint create --region RegionOne image internal http://controller:9292'
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& openstack endpoint create --region RegionOne image admin http://controller:9292'
    machine.vm.provision :shell, :inline => 'yum -y install openstack-glance'
    # /etc/glance/glance-api.conf
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/glance/glance-api.conf',
                  'database', 'connection', '"mysql+pymysql://glance:' + Passwords['GLANCE_DBPASS'] + '@controller/glance"', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/glance/glance-api.conf',
                  'keystone_authtoken', 'auth_uri', 'http://controller:5000', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/glance/glance-api.conf',
                  'keystone_authtoken', 'auth_url', 'http://controller:35357', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/glance/glance-api.conf',
                  'keystone_authtoken', 'memcached_servers', 'controller:11211', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/glance/glance-api.conf',
                  'keystone_authtoken', 'auth_type', 'password', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/glance/glance-api.conf',
                  'keystone_authtoken', 'project_domain_name', 'default', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/glance/glance-api.conf',
                  'keystone_authtoken', 'user_domain_name', 'default', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/glance/glance-api.conf',
                  'keystone_authtoken', 'project_name', 'service', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/glance/glance-api.conf',
                  'keystone_authtoken', 'username', 'glance', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/glance/glance-api.conf',
                  'keystone_authtoken', 'password', Passwords['GLANCE_PASS'], LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/glance/glance-api.conf',
                  'paste_deploy', 'flavor', 'keystone', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/glance/glance-api.conf',
                  'glance_store', 'stores', 'file,http', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/glance/glance-api.conf',
                  'glance_store', 'default_store', 'file', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/glance/glance-api.conf',
                  'glance_store', 'filesystem_store_datadir', '/var/lib/glance/images', LABEL_CRUDINI]
    end
    # /etc/glance/glance-registry.conf
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/glance/glance-registry.conf',
                  'database', 'connection', '"mysql+pymysql://glance:' + Passwords['GLANCE_DBPASS'] + '@controller/glance"', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/glance/glance-registry.conf',
                  'keystone_authtoken', 'auth_uri', 'http://controller:5000', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/glance/glance-registry.conf',
                  'keystone_authtoken', 'auth_url', 'http://controller:35357', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/glance/glance-registry.conf',
                  'keystone_authtoken', 'memcached_servers', 'controller:11211', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/glance/glance-registry.conf',
                  'keystone_authtoken', 'auth_type', 'password', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/glance/glance-registry.conf',
                  'keystone_authtoken', 'project_domain_name', 'default', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/glance/glance-registry.conf',
                  'keystone_authtoken', 'user_domain_name', 'default', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/glance/glance-registry.conf',
                  'keystone_authtoken', 'project_name', 'service', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/glance/glance-registry.conf',
                  'keystone_authtoken', 'username', 'glance', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/glance/glance-registry.conf',
                  'keystone_authtoken', 'password', Passwords['GLANCE_PASS'], LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/glance/glance-registry.conf',
                  'paste_deploy', 'flavor', 'keystone', LABEL_CRUDINI]
    end
    machine.vm.provision :shell, :inline => 'su -s /bin/sh -c "glance-manage db_sync" glance'
    machine.vm.provision :shell, :inline => 'systemctl enable openstack-glance-api.service openstack-glance-registry.service'
    machine.vm.provision :shell, :inline => 'systemctl start openstack-glance-api.service openstack-glance-registry.service'
    # https://docs.openstack.org/ocata/install-guide-rdo/glance-verify.html
    machine.vm.provision :shell, :inline => 'yum -y install wget'
    machine.vm.provision :shell, :inline => 'wget -q http://download.cirros-cloud.net/0.3.5/cirros-0.3.5-x86_64-disk.img -P /root&& setfacl -m u:vagrant:r /root/cirros-0.3.5-x86_64-disk.img'
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& openstack image create "cirros" \
                                             --file /root/cirros-0.3.5-x86_64-disk.img \
                                             --disk-format qcow2 --container-format bare \
                                             --public'
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& openstack image list'
    # https://docs.openstack.org/ocata/install-guide-rdo/nova-controller-install.html
    machine.vm.provision 'shell' do |s|
      s.inline = $create_database
      # MYSQL_ROOT_PASSWORD, DATABASE, USER, PASSWORD
      s.args   = [Passwords['DB_PASSWORD'], 'nova_api', 'nova', Passwords['NOVA_DBPASS']]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $create_database
      # MYSQL_ROOT_PASSWORD, DATABASE, USER, PASSWORD
      s.args   = [Passwords['DB_PASSWORD'], 'nova', 'nova', Passwords['NOVA_DBPASS']]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $create_database
      # MYSQL_ROOT_PASSWORD, DATABASE, USER, PASSWORD
      s.args   = [Passwords['DB_PASSWORD'], 'nova_cell0', 'nova', Passwords['NOVA_DBPASS']]
    end
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& openstack user create --domain default --password ' + Passwords['NOVA_PASS'] + ' nova'
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& openstack role add --project service --user nova admin'
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& openstack service create --name nova --description "OpenStack Compute" compute'
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& openstack endpoint create --region RegionOne compute public http://controller:8774/v2.1'
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& openstack endpoint create --region RegionOne compute internal http://controller:8774/v2.1'
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& openstack endpoint create --region RegionOne compute admin http://controller:8774/v2.1'
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& openstack user create --domain default --password ' + Passwords['PLACEMENT_PASS'] + ' placement'
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& openstack role add --project service --user placement admin'
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& openstack service create --name placement --description "Placement API" placement'
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& openstack endpoint create --region RegionOne placement public http://controller:8778'
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& openstack endpoint create --region RegionOne placement internal http://controller:8778'
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& openstack endpoint create --region RegionOne placement admin http://controller:8778'
    machine.vm.provision :shell, :inline => 'yum -y install openstack-nova-api openstack-nova-conductor \
                                             openstack-nova-console openstack-nova-novncproxy \
                                             openstack-nova-scheduler openstack-nova-placement-api'
    # /etc/nova/nova.conf
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'DEFAULT', 'enabled_apis', 'osapi_compute,metadata', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'api_database', 'connection', '"mysql+pymysql://nova:' + Passwords['NOVA_DBPASS'] + '@controller/nova_api"', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'database', 'connection', '"mysql+pymysql://nova:' + Passwords['NOVA_DBPASS'] + '@controller/nova"', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'DEFAULT', 'transport_url', '"rabbit://openstack:' + Passwords['RABBIT_PASS'] + '@controller"', LABEL_CRUDINI]
    end
    # identity service access
    # auth_strategy is under api on nova, but under DEFAULT on neutron
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'api', 'auth_strategy', 'keystone', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'keystone_authtoken', 'auth_uri', 'http://controller:5000', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'keystone_authtoken', 'auth_url', 'http://controller:35357', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'keystone_authtoken', 'memcached_servers', 'controller:11211', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'keystone_authtoken', 'auth_type', 'password', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'keystone_authtoken', 'project_domain_name', 'default', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'keystone_authtoken', 'user_domain_name', 'default', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'keystone_authtoken', 'project_name', 'service', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'keystone_authtoken', 'username', 'nova', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'keystone_authtoken', 'password', Passwords['NOVA_PASS'], LABEL_CRUDINI]
    end
    # management interface IP address of the controller node
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'DEFAULT', 'my_ip', arch['controller']['IP address'], LABEL_CRUDINI]
    end
    # support for the Networking service
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'DEFAULT', 'use_neutron', 'True', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'DEFAULT', 'firewall_driver', 'nova.virt.firewall.NoopFirewallDriver', LABEL_CRUDINI]
    end
    # VNC
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'vnc', 'enabled', 'true', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'vnc', 'vncserver_listen', '\$my_ip', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'vnc', 'vncserver_proxyclient_address', '\$my_ip', LABEL_CRUDINI]
    end
    # glance
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'glance', 'api_servers', 'http://controller:9292', LABEL_CRUDINI]
    end
    # oslo_concurrency
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'oslo_concurrency', 'lock_path', '/var/lib/nova/tmp', LABEL_CRUDINI]
    end
    # placement
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'placement', 'os_region_name', 'RegionOne', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'placement', 'project_domain_name', 'Default', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'placement', 'project_name', 'service', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'placement', 'auth_type', 'password', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'placement', 'user_domain_name', 'Default', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'placement', 'auth_url', 'http://controller:35357/v3', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'placement', 'username', 'placement', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'placement', 'password', Passwords['PLACEMENT_PASS'], LABEL_CRUDINI]
    end
    machine.vm.provision :shell, :inline => $bugzilla1430540
    machine.vm.provision :shell, :inline => 'systemctl restart httpd'
    machine.vm.provision :shell, :inline => 'su -s /bin/sh -c "nova-manage api_db sync" nova'
    machine.vm.provision :shell, :inline => 'su -s /bin/sh -c "nova-manage cell_v2 map_cell0" nova'
    machine.vm.provision :shell, :inline => 'su -s /bin/sh -c "nova-manage cell_v2 create_cell --name=cell1 --verbose" nova'
    machine.vm.provision :shell, :inline => 'su -s /bin/sh -c "nova-manage db sync" nova'
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& nova-manage cell_v2 list_cells'
    machine.vm.provision :shell, :inline => 'systemctl enable openstack-nova-api.service \
                                             openstack-nova-consoleauth.service openstack-nova-scheduler.service \
                                             openstack-nova-conductor.service openstack-nova-novncproxy.service'
    machine.vm.provision :shell, :inline => 'systemctl start openstack-nova-api.service \
                                             openstack-nova-consoleauth.service openstack-nova-scheduler.service \
                                             openstack-nova-conductor.service openstack-nova-novncproxy.service'
    machine.vm.provision :shell, :inline => SLEEP30
  end
  config.vm.define 'compute1' do |machine|
    node = 'compute1'
    # check the connectivity to controller
    machine.vm.provision :shell, :inline => 'ping -W 1 -c 4 controller'
    # https://docs.openstack.org/ocata/install-guide-rdo/nova-compute-install.html
    machine.vm.provision :shell, :inline => 'yum -y install openstack-nova-compute'
    # /etc/nova/nova.conf
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'DEFAULT', 'enabled_apis', 'osapi_compute,metadata', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'DEFAULT', 'transport_url', '"rabbit://openstack:' + Passwords['RABBIT_PASS'] + '@controller"', LABEL_CRUDINI]
    end
    # identity service access
    # auth_strategy is under api on nova, but under DEFAULT on neutron
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'api', 'auth_strategy', 'keystone', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'keystone_authtoken', 'auth_uri', 'http://controller:5000', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'keystone_authtoken', 'auth_url', 'http://controller:35357', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'keystone_authtoken', 'memcached_servers', 'controller:11211', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'keystone_authtoken', 'auth_type', 'password', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'keystone_authtoken', 'project_domain_name', 'default', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'keystone_authtoken', 'user_domain_name', 'default', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'keystone_authtoken', 'project_name', 'service', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'keystone_authtoken', 'username', 'nova', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'keystone_authtoken', 'password', Passwords['NOVA_PASS'], LABEL_CRUDINI]
    end
    # management interface IP address of your compute node
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'DEFAULT', 'my_ip', arch[node]['IP address'], LABEL_CRUDINI]
    end
    # support for the Networking service
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'DEFAULT', 'use_neutron', 'True', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'DEFAULT', 'firewall_driver', 'nova.virt.firewall.NoopFirewallDriver', LABEL_CRUDINI]
    end
    # VNC
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'vnc', 'enabled', 'true', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'vnc', 'vncserver_listen', '0.0.0.0', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'vnc', 'vncserver_proxyclient_address', '\$my_ip', LABEL_CRUDINI]
    end
    # 
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'vnc', 'novncproxy_base_url', 'http://controller:6080/vnc_auto.html', LABEL_CRUDINI]
    end
    # glance
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'glance', 'api_servers', 'http://controller:9292', LABEL_CRUDINI]
    end
    # oslo_concurrency
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'oslo_concurrency', 'lock_path', '/var/lib/nova/tmp', LABEL_CRUDINI]
    end
    # placement
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'placement', 'os_region_name', 'RegionOne', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'placement', 'project_domain_name', 'Default', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'placement', 'project_name', 'service', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'placement', 'auth_type', 'password', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'placement', 'user_domain_name', 'Default', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'placement', 'auth_url', 'http://controller:35357/v3', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'placement', 'username', 'placement', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'placement', 'password', Passwords['PLACEMENT_PASS'], LABEL_CRUDINI]
    end
    # If this command returns a value of one or greater, your compute node supports hardware acceleration.
    machine.vm.provision :shell, :inline => 'egrep -c "(vmx|svm)" /proc/cpuinfo | grep -q ' + arch[node]['Hardware Requirements']['CPU'].to_s
    machine.vm.provision :shell, :inline => 'systemctl enable libvirtd.service openstack-nova-compute.service'
    machine.vm.provision :shell, :inline => 'systemctl start libvirtd.service openstack-nova-compute.service'
    machine.vm.provision :shell, :inline => SLEEP30
  end
  config.vm.define 'controller' do |machine|
    node = 'controller'
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& openstack hypervisor list'
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& su -s /bin/sh -c "nova-manage cell_v2 discover_hosts --verbose" nova'
    # configure controller node to automatically register new compute nodes
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'scheduler', 'discover_hosts_in_cells_interval', '30', LABEL_CRUDINI]
    end
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& openstack hypervisor list'
    # https://docs.openstack.org/ocata/install-guide-rdo/nova-verify.html
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& openstack compute service list'
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& openstack catalog list'
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& openstack image list'
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& nova-status upgrade check'
    # https://docs.openstack.org/ocata/install-guide-rdo/neutron-controller-install.html
    machine.vm.provision 'shell' do |s|
      s.inline = $create_database
      # MYSQL_ROOT_PASSWORD, DATABASE, USER, PASSWORD
      s.args   = [Passwords['DB_PASSWORD'], 'neutron', 'neutron', Passwords['NEUTRON_DBPASS']]
    end
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& openstack user create --domain default --password '  + Passwords['NEUTRON_PASS'] + ' neutron'
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& openstack role add --project service --user neutron admin'
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& openstack service create --name neutron --description "OpenStack Networking" network'
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& openstack endpoint create --region RegionOne network public http://controller:9696'
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& openstack endpoint create --region RegionOne network internal http://controller:9696'
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& openstack endpoint create --region RegionOne network admin http://controller:9696'
    # https://docs.openstack.org/ocata/install-guide-rdo/neutron-controller-install-option2.html
    machine.vm.provision :shell, :inline => 'yum -y install openstack-neutron openstack-neutron-ml2 openstack-neutron-linuxbridge ebtables'
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/neutron.conf',
                  'database', 'connection', '"mysql+pymysql://neutron:' + Passwords['NEUTRON_DBPASS'] + '@controller/neutron"', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/neutron.conf',
                  'DEFAULT', 'core_plugin', 'ml2', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/neutron.conf',
                  'DEFAULT', 'service_plugins', 'router', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/neutron.conf',
                  'DEFAULT', 'allow_overlapping_ips', 'true', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/neutron.conf',
                  'DEFAULT', 'transport_url', '"rabbit://openstack:' + Passwords['RABBIT_PASS'] + '@controller"', LABEL_CRUDINI]
    end
    # identity service access
    # auth_strategy is under api on nova, but under DEFAULT on neutron
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/neutron.conf',
                  'DEFAULT', 'auth_strategy', 'keystone', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/neutron.conf',
                  'keystone_authtoken', 'auth_uri', 'http://controller:5000', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/neutron.conf',
                  'keystone_authtoken', 'auth_url', 'http://controller:35357', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/neutron.conf',
                  'keystone_authtoken', 'memcached_servers', 'controller:11211', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/neutron.conf',
                  'keystone_authtoken', 'auth_type', 'password', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/neutron.conf',
                  'keystone_authtoken', 'project_domain_name', 'default', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/neutron.conf',
                  'keystone_authtoken', 'user_domain_name', 'default', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/neutron.conf',
                  'keystone_authtoken', 'project_name', 'service', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/neutron.conf',
                  'keystone_authtoken', 'username', 'neutron', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/neutron.conf',
                  'keystone_authtoken', 'password', Passwords['NEUTRON_PASS'], LABEL_CRUDINI]
    end
    # configure Networking to notify Compute of network topology changes
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/neutron.conf',
                  'DEFAULT', 'notify_nova_on_port_status_changes', 'true', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/neutron.conf',
                  'DEFAULT', 'notify_nova_on_port_data_changes', 'true', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/neutron.conf',
                  'nova', 'auth_url', 'http://controller:35357', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/neutron.conf',
                  'nova', 'auth_type', 'password', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/neutron.conf',
                  'nova', 'project_domain_name', 'default', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/neutron.conf',
                  'nova', 'user_domain_name', 'default', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/neutron.conf',
                  'nova', 'region_name', 'RegionOne', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/neutron.conf',
                  'nova', 'project_name', 'service', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/neutron.conf',
                  'nova', 'username', 'nova', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/neutron.conf',
                  'nova', 'password', Passwords['NOVA_PASS'], LABEL_CRUDINI]
    end
    # oslo_concurrency
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/neutron.conf',
                  'oslo_concurrency', 'lock_path', '/var/lib/neutron/tmp', LABEL_CRUDINI]
    end
    # Modular Layer 2 (ML2) plug-in
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/plugins/ml2/ml2_conf.ini',
                  'ml2', 'type_drivers', 'flat,vlan,vxlan', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/plugins/ml2/ml2_conf.ini',
                  'ml2', 'tenant_network_types', 'vxlan', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/plugins/ml2/ml2_conf.ini',
                  'ml2', 'mechanism_drivers', 'linuxbridge,l2population', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/plugins/ml2/ml2_conf.ini',
                  'ml2', 'extension_drivers', 'port_security', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/plugins/ml2/ml2_conf.ini',
                  'ml2_type_flat', 'flat_networks', 'provider', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/plugins/ml2/ml2_conf.ini',
                  'ml2_type_vxlan', 'vni_ranges', '1:1000', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/plugins/ml2/ml2_conf.ini',
                  'securitygroup', 'enable_ipset', 'true', LABEL_CRUDINI]
    end
    # Configure the Linux bridge agent
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/plugins/ml2/linuxbridge_agent.ini',
                  'linux_bridge', 'physical_interface_mappings', 'provider:' + PROVIDER_INTERFACE_NAME, LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/plugins/ml2/linuxbridge_agent.ini',
                  'vxlan', 'enable_vxlan', 'true', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/plugins/ml2/linuxbridge_agent.ini',
                  'vxlan', 'local_ip', arch['controller']['IP address'], LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/plugins/ml2/linuxbridge_agent.ini',
                  'vxlan', 'l2_population', 'true', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/plugins/ml2/linuxbridge_agent.ini',
                  'securitygroup', 'enable_security_group', 'true', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/plugins/ml2/linuxbridge_agent.ini',
                  'securitygroup', 'firewall_driver', 'neutron.agent.linux.iptables_firewall.IptablesFirewallDriver', LABEL_CRUDINI]
    end
    # Configure the layer-3 agent
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/l3_agent.ini',
                  'DEFAULT', 'interface_driver', 'linuxbridge', LABEL_CRUDINI]
    end
    # Configure the DHCP agent
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/dhcp_agent.ini',
                  'DEFAULT', 'interface_driver', 'linuxbridge', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/dhcp_agent.ini',
                  'DEFAULT', 'dhcp_driver', 'neutron.agent.linux.dhcp.Dnsmasq', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/dhcp_agent.ini',
                  'DEFAULT', 'enable_isolated_metadata', 'true', LABEL_CRUDINI]
    end
    # Configure the metadata agent
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/metadata_agent.ini',
                  'DEFAULT', 'nova_metadata_ip', 'controller', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/metadata_agent.ini',
                  'DEFAULT', 'metadata_proxy_shared_secret', Passwords['METADATA_SECRET'], LABEL_CRUDINI]
    end
    # Configure the Compute service to use the Networking service
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'neutron', 'url', 'http://controller:9696', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'neutron', 'auth_url', 'http://controller:35357', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'neutron', 'auth_type', 'password', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'neutron', 'project_domain_name', 'default', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'neutron', 'user_domain_name', 'default', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'neutron', 'region_name', 'RegionOne', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'neutron', 'project_name', 'service', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'neutron', 'username', 'neutron', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'neutron', 'password', Passwords['NEUTRON_PASS'], LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'neutron', 'service_metadata_proxy', 'true', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'neutron', 'metadata_proxy_shared_secret', Passwords['METADATA_SECRET'], LABEL_CRUDINI]
    end
    # Finalize installation
    machine.vm.provision :shell, :inline => 'ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini'
    machine.vm.provision :shell, :inline => 'su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
                                             --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron'
    machine.vm.provision :shell, :inline => 'systemctl restart openstack-nova-api.service'
    machine.vm.provision :shell, :inline => 'systemctl enable neutron-server.service \
                                             neutron-linuxbridge-agent.service neutron-dhcp-agent.service \
                                             neutron-metadata-agent.service'
    machine.vm.provision :shell, :inline => 'systemctl start neutron-server.service \
                                             neutron-linuxbridge-agent.service neutron-dhcp-agent.service \
                                             neutron-metadata-agent.service'
    machine.vm.provision :shell, :inline => 'systemctl enable neutron-l3-agent.service'
    machine.vm.provision :shell, :inline => 'systemctl start neutron-l3-agent.service'
    machine.vm.provision :shell, :inline => SLEEP30
  end
  config.vm.define 'compute1' do |machine|
    node = 'compute1'
    # https://docs.openstack.org/ocata/install-guide-rdo/neutron-compute-install.html
    machine.vm.provision :shell, :inline => 'yum -y install openstack-neutron-linuxbridge ebtables ipset'
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/neutron.conf',
                  'DEFAULT', 'transport_url', '"rabbit://openstack:' + Passwords['RABBIT_PASS'] + '@controller"', LABEL_CRUDINI]
    end
    # identity service access
    # auth_strategy is under api on nova, but under DEFAULT on neutron
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/neutron.conf',
                  'DEFAULT', 'auth_strategy', 'keystone', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/neutron.conf',
                  'keystone_authtoken', 'auth_uri', 'http://controller:5000', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/neutron.conf',
                  'keystone_authtoken', 'auth_url', 'http://controller:35357', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/neutron.conf',
                  'keystone_authtoken', 'memcached_servers', 'controller:11211', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/neutron.conf',
                  'keystone_authtoken', 'auth_type', 'password', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/neutron.conf',
                  'keystone_authtoken', 'project_domain_name', 'default', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/neutron.conf',
                  'keystone_authtoken', 'user_domain_name', 'default', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/neutron.conf',
                  'keystone_authtoken', 'project_name', 'service', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/neutron.conf',
                  'keystone_authtoken', 'username', 'neutron', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/neutron.conf',
                  'keystone_authtoken', 'password', Passwords['NEUTRON_PASS'], LABEL_CRUDINI]
    end
    # oslo_concurrency
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/neutron.conf',
                  'oslo_concurrency', 'lock_path', '/var/lib/neutron/tmp', LABEL_CRUDINI]
    end
    # https://docs.openstack.org/ocata/install-guide-rdo/neutron-compute-install-option2.html
    # Configure the Linux bridge agent
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/plugins/ml2/linuxbridge_agent.ini',
                  'linux_bridge', 'physical_interface_mappings', 'provider:' + PROVIDER_INTERFACE_NAME, LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/plugins/ml2/linuxbridge_agent.ini',
                  'vxlan', 'enable_vxlan', 'true', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/plugins/ml2/linuxbridge_agent.ini',
                  'vxlan', 'local_ip', arch[node]['IP address'], LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/plugins/ml2/linuxbridge_agent.ini',
                  'vxlan', 'l2_population', 'true', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/plugins/ml2/linuxbridge_agent.ini',
                  'securitygroup', 'enable_security_group', 'true', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/neutron/plugins/ml2/linuxbridge_agent.ini',
                  'securitygroup', 'firewall_driver', 'neutron.agent.linux.iptables_firewall.IptablesFirewallDriver', LABEL_CRUDINI]
    end
    # Configure the Compute service to use the Networking service
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'neutron', 'url', 'http://controller:9696', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'neutron', 'auth_url', 'http://controller:35357', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'neutron', 'auth_type', 'password', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'neutron', 'project_domain_name', 'default', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'neutron', 'user_domain_name', 'default', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'neutron', 'region_name', 'RegionOne', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'neutron', 'project_name', 'service', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'neutron', 'username', 'neutron', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'neutron', 'password', Passwords['NEUTRON_PASS'], LABEL_CRUDINI]
    end
    # Finalize installation
    machine.vm.provision :shell, :inline => 'systemctl restart openstack-nova-compute.service'
    machine.vm.provision :shell, :inline => 'systemctl enable neutron-linuxbridge-agent.service'
    machine.vm.provision :shell, :inline => 'systemctl start neutron-linuxbridge-agent.service'
    machine.vm.provision :shell, :inline => SLEEP30
  end
  config.vm.define 'controller' do |machine|
    node = 'controller'
    # https://docs.openstack.org/ocata/install-guide-rdo/neutron-verify.html
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& openstack extension list --network'
    # https://docs.openstack.org/ocata/install-guide-rdo/neutron-verify-option2.html
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& openstack network agent list'
    # https://docs.openstack.org/ocata/install-guide-rdo/launch-instance.html
    # https://docs.openstack.org/ocata/install-guide-rdo/launch-instance-networks-provider.html
    # Create the provider network
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& openstack network create --share --external \
                                             --provider-physical-network provider \
                                             --provider-network-type flat provider'
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& openstack subnet create --network provider \
                                             --allocation-pool start=' + START_IP_ADDRESS + ',end=' + END_IP_ADDRESS + '\
                                             --dns-nameserver ' + DNS_RESOLVER + ' --gateway ' + PROVIDER_NETWORK_GATEWAY + '\
                                             --subnet-range ' + PROVIDER_NETWORK_CIDR + ' provider'
    # https://docs.openstack.org/ocata/install-guide-rdo/launch-instance-networks-selfservice.html
    # Create the self-service network
    machine.vm.provision :shell, :inline => 'source /root/demo-openrc&& openstack network create selfservice'
    machine.vm.provision :shell, :inline => 'source /root/demo-openrc&& openstack subnet create --network selfservice \
                                             --dns-nameserver ' + DNS_RESOLVER + ' --gateway ' + SELFSERVICE_NETWORK_GATEWAY +  '\
                                             --subnet-range ' + SELFSERVICE_NETWORK_CIDR + ' selfservice'
    # Create a router
    machine.vm.provision :shell, :inline => SLEEP30
    machine.vm.provision :shell, :inline => 'source /root/demo-openrc&& openstack router list'
    machine.vm.provision :shell, :inline => 'source /root/demo-openrc&& openstack router create router'
    machine.vm.provision :shell, :inline => SLEEP30
    machine.vm.provision :shell, :inline => 'source /root/demo-openrc&& openstack router list'
    machine.vm.provision :shell, :inline => 'source /root/demo-openrc&& neutron router-interface-add router selfservice'
    machine.vm.provision :shell, :inline => 'source /root/demo-openrc&& neutron router-gateway-set router provider'
    machine.vm.provision :shell, :inline => SLEEP30
    # Verify operation
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& ip netns'
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& neutron router-port-list router'
    # ping the public router IP
    machine.vm.provision :shell, :inline => 'source /root/demo-openrc&& ping -W 1 -c 4 `openstack router show router --column external_gateway_info -f value | jq ".external_fixed_ips[].ip_address" | tr -d \"`'
    # Create m1.nano flavor
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& openstack flavor create --id 0 --vcpus 1 --ram 64 --disk 1 m1.nano'
    # Generate a key pair (as vagrant user)
    machine.vm.provision :shell, :inline => 'sudo su - vagrant -c \"ssh-keygen -f ~/.ssh/id_rsa -t rsa -q -N ""\"'
    machine.vm.provision :shell, :inline => 'source /root/demo-openrc&& openstack keypair create --public-key ~vagrant/.ssh/id_rsa.pub mykey'
    #machine.vm.provision :shell, :inline => 'setfacl -m u:vagrant:r ~/.ssh/id_rsa ~/.ssh/id_rsa.pub'
    machine.vm.provision :shell, :inline => 'source /root/demo-openrc&& openstack keypair list'
    # Add security group rules
    machine.vm.provision :shell, :inline => 'source /root/demo-openrc&& openstack security group rule create --proto icmp default'
    machine.vm.provision :shell, :inline => 'source /root/demo-openrc&& openstack security group rule create --proto tcp --dst-port 22 default'
    machine.vm.provision :shell, :inline => 'sleep 10'
    machine.vm.provision :shell, :inline => 'source /root/demo-openrc&& openstack security group rule list default'
    # https://docs.openstack.org/ocata/install-guide-rdo/launch-instance-provider.html
    machine.vm.provision :shell, :inline => 'source /root/demo-openrc&& openstack flavor list'
    machine.vm.provision :shell, :inline => 'source /root/demo-openrc&& openstack image list'
    machine.vm.provision :shell, :inline => 'source /root/demo-openrc&& openstack network list'
    machine.vm.provision :shell, :inline => 'source /root/demo-openrc&& openstack security group list'
    # Verify access to the provider physical network gateway
    machine.vm.provision :shell, :inline => 'ping -W 1 -c 4 ' + PROVIDER_NETWORK_GATEWAY
    # Verify access to the self-service network gateway
    #machine.vm.provision :shell, :inline => 'ping -W 1 -c 4 ' + SELFSERVICE_NETWORK_GATEWAY  # MDTMP - should that work now?
    # https://docs.openstack.org/ocata/install-guide-rdo/horizon-install.html
    machine.vm.provision :shell, :inline => 'yum -y install openstack-dashboard'
    machine.vm.provision :shell, :inline => 'echo "# Added by Vagrant" >> /etc/openstack-dashboard/local_settings'
    machine.vm.provision :shell, :inline => 'echo OPENSTACK_HOST = \"controller\" >> /etc/openstack-dashboard/local_settings'
    machine.vm.provision :shell, :inline => 'echo ALLOWED_HOSTS = [\"*\"] >> /etc/openstack-dashboard/local_settings'
    # https://ask.openstack.org/en/question/91657/runtimeerror-unable-to-create-a-new-session-key-it-is-likely-that-the-cache-is-unavailable-authorization-failed-the-request-you-have-made-requires/
    #machine.vm.provision :shell, :inline => 'echo SESSION_ENGINE = \"django.contrib.sessions.backends.cache\" >> /etc/openstack-dashboard/local_settings'
    machine.vm.provision :shell, :inline => 'echo SESSION_ENGINE = \"django.contrib.sessions.backends.file\" >> /etc/openstack-dashboard/local_settings'
    machine.vm.provision :shell, :inline => 'echo CACHES = {\"default\": {\"BACKEND\": \"django.core.cache.backends.memcached.MemcachedCache\", \"LOCATION\": \"controller:11211\",}} >> /etc/openstack-dashboard/local_settings'
    machine.vm.provision :shell, :inline => 'echo OPENSTACK_KEYSTONE_URL = \"http://%s:5000/v3\" % OPENSTACK_HOST >> /etc/openstack-dashboard/local_settings'
    machine.vm.provision :shell, :inline => 'echo OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True >> /etc/openstack-dashboard/local_settings'
    machine.vm.provision :shell, :inline => 'echo OPENSTACK_API_VERSIONS = {\"identity\": 3, \"image\": 2, \"volume\": 2,} >> /etc/openstack-dashboard/local_settings'
    machine.vm.provision :shell, :inline => 'echo OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = \"Default\" >> /etc/openstack-dashboard/local_settings'
    machine.vm.provision :shell, :inline => 'echo OPENSTACK_KEYSTONE_DEFAULT_ROLE = \"user\" >> /etc/openstack-dashboard/local_settings'
    # Finalize installation
    machine.vm.provision :shell, :inline => 'systemctl restart httpd.service memcached.service'
    # https://ask.openstack.org/en/question/94959/testing-horizon-with-curl/
    machine.vm.provision :shell, :inline => 'yum -y install npm'
    # https://github.com/ariya/phantomjs/issues/10904
    machine.vm.provision :shell, :inline => 'yum -y install fontconfig'
    machine.vm.provision :shell, :inline => 'npm install --global pageres-cli'
    machine.vm.provision :shell, :inline => 'sudo -u vagrant pageres "http://controller/dashboard/admin/networks/" --cookie="`sh /vagrant/get_horizon_session_cookie.sh`"'
    # https://docs.openstack.org/ocata/install-guide-rdo/cinder-controller-install.html
    machine.vm.provision 'shell' do |s|
      s.inline = $create_database
      # MYSQL_ROOT_PASSWORD, DATABASE, USER, PASSWORD
      s.args   = [Passwords['DB_PASSWORD'], 'cinder', 'cinder', Passwords['CINDER_DBPASS']]
    end
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& openstack user create --domain default --password '  + Passwords['CINDER_PASS'] + ' cinder'
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& openstack role add --project service --user cinder admin'
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& openstack service create --name cinderv2 --description "OpenStack Block Storage" volumev2'
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& openstack service create --name cinderv3 --description "OpenStack Block Storage" volumev3'
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& openstack endpoint create --region RegionOne volumev2 public http://controller:8776/v2/%\(project_id\)s'
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& openstack endpoint create --region RegionOne volumev2 internal http://controller:8776/v2/%\(project_id\)s'
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& openstack endpoint create --region RegionOne volumev2 admin http://controller:8776/v2/%\(project_id\)s'
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& openstack endpoint create --region RegionOne volumev3 public http://controller:8776/v3/%\(project_id\)s'
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& openstack endpoint create --region RegionOne volumev3 internal http://controller:8776/v3/%\(project_id\)s'
    machine.vm.provision :shell, :inline => 'source /root/admin-openrc&& openstack endpoint create --region RegionOne volumev3 admin http://controller:8776/v3/%\(project_id\)s'
    machine.vm.provision :shell, :inline => 'yum -y install openstack-cinder'
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/cinder/cinder.conf',
                  'database', 'connection', '"mysql+pymysql://cinder:' + Passwords['CINDER_DBPASS'] + '@controller/cinder"', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/cinder/cinder.conf',
                  'DEFAULT', 'transport_url', '"rabbit://openstack:' + Passwords['RABBIT_PASS'] + '@controller"', LABEL_CRUDINI]
    end
    # identity service access
    # auth_strategy is under api on nova, but under DEFAULT on cinder
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/cinder/cinder.conf',
                  'DEFAULT', 'auth_strategy', 'keystone', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/cinder/cinder.conf',
                  'keystone_authtoken', 'auth_uri', 'http://controller:5000', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/cinder/cinder.conf',
                  'keystone_authtoken', 'auth_url', 'http://controller:35357', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/cinder/cinder.conf',
                  'keystone_authtoken', 'memcached_servers', 'controller:11211', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/cinder/cinder.conf',
                  'keystone_authtoken', 'auth_type', 'password', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/cinder/cinder.conf',
                  'keystone_authtoken', 'project_domain_name', 'default', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/cinder/cinder.conf',
                  'keystone_authtoken', 'user_domain_name', 'default', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/cinder/cinder.conf',
                  'keystone_authtoken', 'project_name', 'service', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/cinder/cinder.conf',
                  'keystone_authtoken', 'username', 'cinder', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/cinder/cinder.conf',
                  'keystone_authtoken', 'password', Passwords['CINDER_PASS'], LABEL_CRUDINI]
    end
    # management interface IP address of the controller node
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/cinder/cinder.conf',
                  'DEFAULT', 'my_ip', arch['controller']['IP address'], LABEL_CRUDINI]
    end
    # oslo_concurrency
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/cinder/cinder.conf',
                  'oslo_concurrency', 'lock_path', '/var/lib/cinder/tmp', LABEL_CRUDINI]
    end
    machine.vm.provision :shell, :inline => 'su -s /bin/sh -c "cinder-manage db sync" cinder'
    # Configure Compute to use Block Storage
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/nova/nova.conf',
                  'cinder', 'os_region_name', 'RegionOne', LABEL_CRUDINI]
    end
    machine.vm.provision :shell, :inline => 'systemctl restart openstack-nova-api.service'
    machine.vm.provision :shell, :inline => 'systemctl enable openstack-cinder-api.service openstack-cinder-scheduler.service'
    machine.vm.provision :shell, :inline => 'systemctl start openstack-cinder-api.service openstack-cinder-scheduler.service'
    machine.vm.provision :shell, :inline => SLEEP30
  end
  config.vm.define 'block1' do |machine|
    node = 'block1'
    # https://docs.openstack.org/newton/install-guide-rdo/cinder-storage-install.html
    machine.vm.provision :shell, :inline => 'yum -y install lvm2'
    machine.vm.provision :shell, :inline => 'systemctl enable lvm2-lvmetad.service'
    machine.vm.provision :shell, :inline => 'systemctl start lvm2-lvmetad.service'
    machine.vm.provision :shell, :inline => 'if `pvs /dev/vdb > /dev/null`; then pvremove /dev/vdb; fi'
    machine.vm.provision :shell, :inline => 'pvcreate /dev/vdb'
    machine.vm.provision :shell, :inline => 'if `vgs cinder-volumes > /dev/null`; then vgremove -f cinder-volumes; fi'
    machine.vm.provision :shell, :inline => 'vgcreate cinder-volumes /dev/vdb'
    machine.vm.provision :shell, :inline => 'sed -i "/Accept every block device:/i   filter = [ \"a/vda/\", \"a/vdb/\", \"r/.*/\"]" /etc/lvm/lvm.conf'
    machine.vm.provision :shell, :inline => 'yum -y install openstack-cinder targetcli python-keystone'
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/cinder/cinder.conf',
                  'database', 'connection', '"mysql+pymysql://cinder:' + Passwords['CINDER_DBPASS'] + '@controller/cinder"', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/cinder/cinder.conf',
                  'DEFAULT', 'transport_url', '"rabbit://openstack:' + Passwords['RABBIT_PASS'] + '@controller"', LABEL_CRUDINI]
    end
    # identity service access
    # auth_strategy is under api on nova, but under DEFAULT on cinder
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/cinder/cinder.conf',
                  'DEFAULT', 'auth_strategy', 'keystone', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/cinder/cinder.conf',
                  'keystone_authtoken', 'auth_uri', 'http://controller:5000', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/cinder/cinder.conf',
                  'keystone_authtoken', 'auth_url', 'http://controller:35357', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/cinder/cinder.conf',
                  'keystone_authtoken', 'memcached_servers', 'controller:11211', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/cinder/cinder.conf',
                  'keystone_authtoken', 'auth_type', 'password', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/cinder/cinder.conf',
                  'keystone_authtoken', 'project_domain_name', 'default', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/cinder/cinder.conf',
                  'keystone_authtoken', 'user_domain_name', 'default', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/cinder/cinder.conf',
                  'keystone_authtoken', 'project_name', 'service', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/cinder/cinder.conf',
                  'keystone_authtoken', 'username', 'cinder', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/cinder/cinder.conf',
                  'keystone_authtoken', 'password', Passwords['CINDER_PASS'], LABEL_CRUDINI]
    end
    # management interface IP address of the controller node
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/cinder/cinder.conf',
                  'DEFAULT', 'my_ip', arch['controller']['IP address'], LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/cinder/cinder.conf',
                  'lvm', 'volume_driver', 'cinder.volume.drivers.lvm.LVMVolumeDriver', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/cinder/cinder.conf',
                  'lvm', 'volume_group', 'cinder-volumes', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/cinder/cinder.conf',
                  'lvm', 'iscsi_protocol', 'iscsi', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/cinder/cinder.conf',
                  'lvm', 'iscsi_helper', 'lioadm', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/cinder/cinder.conf',
                  'DEFAULT', 'enabled_backends', 'lvm', LABEL_CRUDINI]
    end
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/cinder/cinder.conf',
                  'DEFAULT', 'glance_api_servers', 'http://controller:9292', LABEL_CRUDINI]
    end
    # oslo_concurrency
    machine.vm.provision 'shell' do |s|
      s.inline = $crudini_set
      # config_file, section, parameter, value, label_crudini
      s.args   = ['/etc/cinder/cinder.conf',
                  'oslo_concurrency', 'lock_path', '/var/lib/cinder/tmp', LABEL_CRUDINI]
    end
    machine.vm.provision :shell, :inline => 'systemctl enable openstack-cinder-volume.service target.service'
    machine.vm.provision :shell, :inline => 'systemctl start openstack-cinder-volume.service target.service'
    machine.vm.provision :shell, :inline => SLEEP30
  end
end
