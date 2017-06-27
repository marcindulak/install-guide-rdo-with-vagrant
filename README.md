-----------
Description
-----------

An unattended https://docs.openstack.org/ocata/install-guide-rdo performed on CentOS 7 nodes managed by `vagrant`
using libvirt/kvm nested virtualization. Requires a Linux host.

[Vagrantfile](Vagrantfile) follows the guide as closely as possible,
therefore no configuration management tools (Puppet, Ansible, ...) are used. What a [crudini](https://github.com/pixelb/crudini) feast!

Only the `openstack` core components necessary to launch an instance according to https://docs.openstack.org/ocata/install-guide-rdo/launch-instance.html
are configured. The actual process of launching of an instance is performed outside of [Vagrantfile](Vagrantfile), and documented using command line.

The purpose of this setup is to serve as a repeatable base for learning about `openstack` components.
It is similar to https://github.com/openstack/training-labs except that this setup focuses on bringing up and
configuring all components of the rdo guide in an unattended way.

Currently the setup includes: `keystone`, `glance`, `nova`, `neutron`, `horizon` and `cinder`.

The setup requires 8GB RAM and 10GB disk space.

Tested on:

- Ubuntu 16.04 x86_64, Vagrant 1.9.5


----------------------
Configuration overview
----------------------

The network setup uses "Networking Option 2: Self-service networks" https://docs.openstack.org/ocata/install-guide-rdo/neutron-controller-install-option2.html,
presented on the horizon dashboard as follows:

![http://controller/dashboard/admin/networks/](https://raw.github.com/marcindulak/install-guide-rdo-with-vagrant/master/screenshots/controller!dashboard!admin!networks-1366x768.png)

`vagrant` reserves eth0 and this cannot be currently changed (see https://github.com/mitchellh/vagrant/issues/2093).

The private networks are assigned to the eth1 (`install-guide-rdo-with-vagrant-management`) and eth2 interfaces
(`install-guide-rdo-with-vagrant-provider`) according to the `Network Layout`
depicted at https://docs.openstack.org/ocata/install-guide-rdo/environment-networking.html
The **X** denotes the possibility of horizontal scaling of the given `openstack` component located on the given server VM,
by increasing the count of **X** in [Vagrantfile](Vagrantfile).


                                             -----------
                                             | Vagrant |
       ---------------                       |   HOST  |                       ---------------
       | controller1 | eth0 192.168.122.0/24 |         | eth0 192.168.122.0/24 | blockX      |
       |             |---------------------- |         |-----------------------|             | 
       | keystone    |                       |         |                       | cinder      |
       | glance      |   eth1 10.0.0.11/24   |         |   eth1 10.0.0.4X/24   |             |
       | nova        |-----------------------|         |-----------------------|             |
       | neutron     |                       |         |                       |             |
       | horizon     |  eth2 203.0.113.0/24  |         |  eth2 203.0.113.0/24  |             |
       | cinder      |-----------------------|         |-----------------------|             |
       |             |                       |         |                       |             |
       ---------------                       |         |                       ---------------
                                             |         |
       ---------------                       |         |
       | computeX    | eth0 192.168.122.0/24 |         |
       |             |---------------------- |         |
       | nova        |                       |         |
       | neutron     |   eth1 10.0.0.3X/24   |         |
       |             |-----------------------|         |
       |             |                       |         |
       |             |  eth2 203.0.113.0/24  |         |
       |             |-----------------------|         |
       |             |                       |         |
       ---------------                       |         |
                                             |         |
                                             -----------


------------------
Vagrant Host setup
------------------

Install `vagrant` https://www.vagrantup.com/downloads.html

Make sure nested virtualization is enabled on your host (e.g. your laptop):

        $ modinfo kvm_intel | grep -i nested

Install, configure libvirt:

- Debian/Ubuntu:

        $ sudo apt-get -y install kvm libvirt-bin
        $ sudo adduser $USER libvirtd  # logout and login again

  Install https://github.com/pradels/vagrant-libvirt plugin dependencies:

        $ sudo apt-get install -y ruby-libvirt
        $ sudo apt-get install -y libxslt-dev libxml2-dev libvirt-dev zlib1g-dev

  Disable the default libvirt network:

        $ virsh net-autostart default --disable
        $ sudo service libvirt-bin restart

- Fedora/RHEL7:

  TODO


------------
Sample Usage
------------

Configure the `openstack` components with:

        $ git clone https://github.com/marcindulak/install-guide-rdo-with-vagrant.git
        $ cd install-guide-rdo-with-vagrant
        $ for net in `virsh -q net-list --all | grep install-guide-rdo-with-vagrant | awk '{print $1}'`; do virsh net-destroy $net; virsh net-undefine $net; done  # cleanup any leftover networks if this is not the first run
        $ vagrant plugin install vagrant-libvirt
        $ vagrant up --no-parallel controller compute1 block1

Verify the network settings of the VMs match the diagram above:

        $ virsh net-list
        $ virsh net-dumpxml install-guide-rdo-with-vagrant-management
        $ virsh net-dumpxml install-guide-rdo-with-vagrant-provider

Launching an instance is performed as **demo** user according to https://docs.openstack.org/ocata/install-guide-rdo/launch-instance-selfservice.html

- "Determine instance options":

        $ vagrant ssh controller -c "source /root/demo-openrc&& openstack flavor list"

- "List available images":

        $ vagrant ssh controller -c "source /root/demo-openrc&& openstack image list"

- "List available networks":

        $ vagrant ssh controller -c "source /root/demo-openrc&& openstack network list"

- "List available security groups":

        $ vagrant ssh controller -c "source /root/demo-openrc&& openstack security group list"

- Make sure the `conpute1` host is discovered:

        $ vagrant ssh controller -c "source /root/admin-openrc&& sudo su -s /bin/sh -c 'nova-manage cell_v2 discover_hosts --verbose' nova"

- "Launch the instance":

        $ vagrant ssh controller -c 'source /root/demo-openrc&& openstack server create --flavor m1.nano --image cirros --nic net-id=`openstack network show selfservice -f json | jq ".id" | tr -d \"` --security-group default --key-name mykey selfservice-instance'

- "Check the status of your instance":

        $ vagrant ssh controller -c "source /root/demo-openrc&& openstack server list"
        $ sleep 30
        $ vagrant ssh controller -c "source /root/demo-openrc&& openstack server list"
        $ vagrant ssh controller -c "source /root/demo-openrc&& openstack server show selfservice-instance"

- "Create a floating IP address on the provider virtual network":

        $ vagrant ssh controller -c "source /root/demo-openrc&& source /root/demo-openrc&& openstack floating ip create provider"

- "Associate the floating IP address with the instance:"

        $ IP=$(vagrant ssh controller -c "source /root/demo-openrc&& openstack floating ip list -f value | cut -d' ' -f2 | tr -d '\r\n'")
        $ vagrant ssh controller -c "source /root/demo-openrc&& openstack server add floating ip selfservice-instance $IP"

- "Verify connectivity to the instance via floating IP address":

        $ vagrant ssh controller -c 'source /root/demo-openrc&& ping -W 1 -c 4 `openstack server show selfservice-instance -f json -c addresses |  jq ".addresses" | tr -d \" | tr -d " " | cut -d, -f2`'

- "Access your instance using SSH".

        $ vagrant ssh controller -c 'source /root/demo-openrc&& ssh -i ~vagrant/.ssh/id_rsa -o StrictHostKeyChecking=no cirros@`openstack server show selfservice-instance -f json -c addresses |  jq ".addresses" | tr -d \" | tr -d " " | cut -d, -f2` ip addr show'

Attach block storage to the instance according to https://docs.openstack.org/ocata/install-guide-rdo/launch-instance-cinder.html

- "Create a volume":

        $ vagrant ssh controller -c "source /root/demo-openrc&& openstack volume create --size 1 volume1"
        $ sleep 30
        $ vagrant ssh controller -c "source /root/demo-openrc&& openstack volume list"

- "Attach the volume to an instance":

        $ vagrant ssh controller -c "source /root/demo-openrc&& openstack server add volume selfservice-instance volume1"
        $ sleep 30
        $ vagrant ssh controller -c "source /root/demo-openrc&& openstack volume list"

   and verify the presence of the volume (TODO: attaching this volume fails, investigating this):

        $ vagrant ssh controller -c 'source /root/demo-openrc&& ssh -i ~vagrant/.ssh/id_rsa -o StrictHostKeyChecking=no cirros@`openstack server show selfservice-instance -f json -c addresses |  jq ".addresses" | tr -d \" | tr -d " " | cut -d, -f2` sudo fdisk -l /dev/vdb'

The horizon dashboard is accessible on and **outside** of your `vagrant` host port 8080. If you prefer to disable external access to this port
modify the `forwarded_port` line of [Vagrantfile](Vagrantfile) according to https://github.com/vagrant-libvirt/vagrant-libvirt#forwarded-ports
See [Vagrantfile](Vagrantfile) for **admin** and **demo** users credentials.

        $ firefox http://localhost:8080/dashboard

Use e.g. https://github.com/sindresorhus/pageres for making unattended screenshots of horizon, from `controller`, where `pageres` is already installed:

        $ vagrant ssh controller -c 'sudo su - vagrant -c "pageres http://controller/dashboard/admin/networks/ --cookie=\"$(sh /vagrant/get_horizon_session_cookie.sh)\""'

of from the `vagrant` host:

        $ COOKIE=$(vagrant ssh controller -c "sh /vagrant/get_horizon_session_cookie.sh")
        $ pageres 'http://localhost:8080/dashboard/admin/networks/' --cookie="$COOKIE"

TODO: create another user and launch another instance.

When done, destroy the test machines with:

        $ vagrant destroy -f


------------
Dependencies
------------

https://github.com/pradels/vagrant-libvirt


-------
License
-------

BSD 2-clause


-----------------------------
Bugs found using this project
-----------------------------

- https://bugs.launchpad.net/openstack-manuals/+bug/1698455


----
Todo
----


--------
Problems
--------

