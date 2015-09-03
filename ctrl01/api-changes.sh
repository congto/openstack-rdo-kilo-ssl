# Used to alter openstack API config files to enable Keystone SSL 
# Use at your own peril

#For cert verification errors
sed -i  '/\[keystone\_authtoken\]/ainsecure\=True' /etc/neutron/neutron.conf
sed -i  '/\[keystone\_authtoken\]/ainsecure\=True' /etc/nova/nova.conf
sed -i  '/\[filter\:authtoken\]/ainsecure\=True' /etc/nova/api-paste.ini
sed -i  '/\[keystone\_authtoken\]/ainsecure\=True' /etc/ceilometer/ceilometer.conf
sed -i  '/\[keystone\_authtoken\]/ainsecure\=True' /etc/glance/glance-api.conf
sed -i  '/\[keystone\_authtoken\]/ainsecure\=True' /etc/glance/glance-registry.conf

#without this change you will get a 500 error creating instances - 
sed -i  '/^admin\_auth\_url/ainsecure\=True' /etc/nova/nova.conf


sed -i  '/\[keystone\_authtoken\]/ainsecure\=True' /etc/cinder/cinder.conf

#to stop novnc console listening on all ip addreses
f='novncproxy_host=0.0.0.0'
g='novncproxy_host=192.168.0.110'

sed -i  "s@^$f\$@$g@" /etc/nova/nova.conf

f='auth_uri[ ]*=[ ]*http://192.168.0.100:5000/'
g='auth_uri=https://192.168.0.100:5000/'
sed -i  "s@^$f@$g@" /etc/nova/nova.conf
sed -i  "s@^$f@$g@" /etc/cinder/api-paste.ini
sed -i  "s@^$f@$g@" /etc/neutron/neutron.conf
sed -i  "s@^$f@$g@" /etc/neutron/api-paste.ini
sed -i  "s@^$f@$g@" /etc/ceilometer/ceilometer.conf
sed -i  "s@^$f@$g@" /etc/glance/glance-api.conf
sed -i  "s@^$f@$g@" /etc/glance/glance-registry.conf

f='auth_protocol[ ]*=[ ]*http'
g='auth_protocol=https'

sed -i  "s@^$f\$@$g@" /etc/nova/nova.conf
sed -i  "s@^$f@$g@" /etc/cinder/api-paste.ini
sed -i  "s@^$f@$g@" /etc/neutron/neutron.conf
sed -i  "s@^$f@$g@" /etc/neutron/api-paste.ini
sed -i  "s@^$f@$g@" /etc/ceilometer/ceilometer.conf

f='admin_auth_url[ ]*=[ ]*http://192.168.0.100:35357/v2.0'
g='admin_auth_url=https://192.168.0.100:35357/v2.0'

sed -i  "s@^$f@$g@" /etc/nova/nova.conf

f='nova_admin_auth_url[ ]*=[ ]*http://192.168.0.100:35357/v2.0'
g='nova_admin_auth_url=https://192.168.0.100:35357/v2.0'

sed -i  "s@^$f@$g@" /etc/neutron/neutron.conf


# without this change instances create in an error state
f='# nova_api_insecure = False'
g='nova_api_insecure = True'

sed -i  "s@^$f@$g@" /etc/neutron/neutron.conf

f='auth_url[ ]*=[ ]*http://192.168.0.100:35357/v2.0'
g='auth_url=https://192.168.0.100:35357/v2.0'

sed -i  "s@^$f@$g@" /etc/neutron/metadata_agent.ini

f='os_auth_url[ ]*=[ ]*http://192.168.0.100:35357/v2.0'
g='os_auth_url=https://192.168.0.100:35357/v2.0'


sed -i  "s@^$f@$g@" /etc/ceilometer/ceilometer.conf

f='identity_uri[ ]*=[ ]*http://192.168.0.100:35357'
g='identity_uri=https://192.168.0.100:35357'

sed -i  "s@^$f@$g@" /etc/glance/glance-api.conf

f='auth_url[ ]*=[ ]*http://localhost:5000/v2.0'
g='auth_url=https://192.168.0.100:5000/v2.0'

sed -i  "s@^$f@$g@" /etc/glance/glance-cache.conf

f='identity_uri[ ]*=[ ]*http://192.168.0.100:35357'
g='identity_uri=https://192.168.0.100:35357'

sed -i  "s@^$f@$g@" /etc/glance/glance-registry.conf

#For Horizon keystone access

f='OPENSTACK_KEYSTONE_URL = "http://192.168.0.100:5000/v2.0"'
g='OPENSTACK_KEYSTONE_URL = "https://192.168.0.100:5000/v2.0"'

sed -i  "s@^$f@$g@" /etc/openstack-dashboard/local_settings

f='# OPENSTACK_SSL_NO_VERIFY = True'
g='OPENSTACK_SSL_NO_VERIFY = True'

sed -i  "s@^$f@$g@" /etc/openstack-dashboard/local_settings

f='#public_endpoint = <None>'
g='public_endpoint = https://192.168.0.100:5000'

sed -i  "s@^$f@$g@" /etc/keystone/keystone.conf

f='#admin_endpoint = <None>'
g='admin_endpoint = https://192.168.0.100:35357'

sed -i  "s@^$f@$g@" /etc/keystone/keystone.conf
