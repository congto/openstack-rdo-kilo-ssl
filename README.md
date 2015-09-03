# openstack-rdo-kilo-ssl
Working RDO openstack Kilo with Keystone API SSL enabled with self-signed certs
####Aim

To use packstack to install RDO Kilo on Centos7 and then to secure Keystone API with self-signed certs.
This is a good way to test SSL before applying it to a production system.

####Infrastructure

2 compute nodes (Centos 7)
1 controller  (Centos 7)
1 NFS server (Centos 7)

####Environment

VMware vCloud

####Networking Overview

* Tenant - 192.168.2.0/24 (non-routed, private)
* Everything else - 192.168.0.0/24 (routed)

* “nfs" - nfs server 192.168.0.102 (1 NIC)
* “ctrl01” - Controller/Network node 192.168.0.100,192.168.0.110,192.168.0.111,192.168.2.100 (3 NICS)
* “compute01” - Compute node 192.168.0.103,192.168.2.103 (2 NICS)
* “compute02” - Compute node 192.168.0.101,192.168.2.101 (2 NICS)

ctrl01 has one NIC with a primary and two secondary addresses on the same subnet, one NIC for the tenant network and one for the external bridge for floating IP access, no ip address, but attached to the routed network.

####Node preparation

#####For all nodes - 

 First confgure network config files as per files in repo under node name.
 
 Add to <code>/etc/hosts</code>
 
 <pre>
192.168.0.101 compute02
192.168.0.102 nfs
192.168.0.103 compute01
192.168.0.100 ctrl01
</pre>
 
 
 Then run the following commands- 


<pre>
yum update -y
yum -y install ntp
systemctl enable ntpd.service
systemctl start ntpd.service
systemctl stop firewalld.service
systemctl disable firewalld.service
sed -i 's/enforcing/disabled/g' /etc/selinux/config
echo 0 > /sys/fs/selinux/enforce
echo 'net.ipv4.conf.all.rp_filter=0' >> /etc/sysctl.conf
echo 'net.ipv4.conf.default.rp_filter=0' >> /etc/sysctl.conf
sysctl -p
service NetworkManager stop
chkconfig NetworkManager off
</pre>

#####Additionally for ctrl01 only- 

<pre>echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
sudo yum install -y https://rdoproject.org/repos/rdo-release.rpm
sudo yum install -y openstack-packstack
</pre>

####Kilo Install

This is using a vxlan tenant tenwork

* Generate new answer file on ctrl01 <code>packstack --gen-answer-file=FILE</code>
* Change the config to match my answer file called kilo.cfg in the [ctrl01 directory in the repo] (ctrl01/kilo.cfg)
* Install Kilo <code>packstack --answer-file=FILE</code>
* Enable the external bridge to third NIC on ctrl01 to allow floating ips to work <code>ovs-vsctl add-port br-ex eno50332184</code>. See file ovsconfig.txt in ctrl01 repo folder.
* Edit <code>vi /etc/httpd/conf.d/15-horizon_vhost.conf</code> and add <code>Server Alias *</code> to Server Aliases section, otherwise you may get the error 'dashboard not found' when logging into Horizon.

####SSL Termination

#####Alter keystone endpoints

<pre>

source keystonerc_admin

keystone service-list | grep keystone
keystone endpoint-list | grep [uuid of keysone service]

keystone endpoint-create --region RegionOne --service-id [uuid of keysone service] \
--publicurl "https://192.168.0.100:5000/v2.0" \
--internalurl "http://192.168.0.111:5000/v2.0" \
--adminurl "https://192.168.0.100:35357/v2.0"

keystone endpoint-delete [uuid of old keysone endpoint]

</pre>

#####Install HAproxy on crtl01 

<pre>
yum install haproxy -y
chkconfig haproxy on
mkdir /etc/haproxy/ssl

</pre>

#####Create self signed cert and turn into .pem file

<pre>
cd /etc/haproxy/ssl
openssl genrsa -out haproxy.key 2048
openssl req -new -sha256 -key haproxy.key -out haproxy.csr
openssl x509 -req -days 365 -in haproxy.csr -signkey haproxy.key -out haproxy.crt
cat haproxy.crt haproxy.key >> haproxy.pem
</pre>

#####Configure HAProxy

<code>/etc/haproxy/haproxy.cfg</code> - [use config file here] (ctrl01/haproxy.cfg)

#####Configure httpd

Replace <code>/etc/httpd/conf/ports.conf</code> with [this file](ctrl01/ports.conf)

Note - 

The python-keystoneclient is deprecated. It still works as normal but with an warning. This old Python Eventlet is not loaded (systemctl status openstack-keystone), and a new http wsgi is running instead on the same ports (5000 and 35357) <code> netstat -lntp | grep '5000\|35357'</code>.The issue is that they are listening by default on 0.0.0.0 which precludes any other service listening on any ip address on these ports. This is a problem for HAProxy. A workaround is simply to alter <code>/etc/httpd/conf/ports.conf</code> and specify the public address AND port rather than just the port number


#####API config file changes


There are two main areas of change to all of the API config files-

* To allow for no certificate verification as self-signed cert will cause errors
* Make keystone API calls https

There are simply loads of line changes so it is best to let sed do the heavy lifting. I have created a file [here](ctrl01/api-changes.sh) to do this on the ctrl01


The compute nodes also need a few changes as follows - 


<code>/etc/nova/nova.conf</code>
<pre>
admin_auth_url=http://192.168.0.111:35357/v2.0
novncproxy_base_url=https://[external ip]:6080/vnc_auto.html
vncserver_proxyclient_address=[ip address of compute node]
</pre>

####Added Horizon security

<code>/etc/openstack-dashboard/local_settings</code>

<pre>
CSRF_COOKIE_SECURE = True
SESSION_COOKIE_SECURE = True

</pre>

Documented here <http://docs.openstack.org/developer/horizon/topics/deployment.html#secure-site-recommendations>

###And Finally


Reboot compute nodes and controller. 

You now should be able to access Horizon and the novnc console over https, and all Keystone API calls will be secure. 

Note that in my environment I have a routed network which was attached to an edge gateway with a publicly routable address. This way I would put in NAT rules to forward traffic.


You will now need to use  --insecure whist using the python client to avoid certificate verification errors - 

<pre> 
. keystonerc_admin
nova --insecure list
glance --insecure image-list</pre>

You will also need to change your credentials file to https <code>/root/keystonerc_admin</code>


<pre>
[root@ctrl01 ~]# cat keystonerc_admin
export OS_USERNAME=admin
export OS_TENANT_NAME=admin
export OS_PASSWORD=xxxxxx
export OS_AUTH_URL=https://192.168.0.100:5000/v2.0/
export OS_REGION_NAME=RegionOne
export PS1='[\u@\h \W(keystone_admin)]\$ '

</pre>













