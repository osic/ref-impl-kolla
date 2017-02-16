import yaml
import os
import subprocess
file = os.path.abspath("/etc/kolla/globals.yml")
f1 = open(file)
stream = yaml.load(f1)
if "ubuntu" in stream['kolla_base_distro'] and "source" in stream['kolla_install_type'] and "3.0.0" in stream['openstack_release']:
   print "Distros and release verified"
if "bond0.200" in stream["network_interface"] and "bond1" in stream["neutron_external_interface"]:
   print "Interface verified"
else:
   os.system("sudo sed -i \'s/^#network_interface.*/network_interface: \"bond0.200\"/g\'"+ file)
   os.system("sudo sed -i \'s/^neutron_external_interface.*/neutron_external_interface: \"bond1\"/g\'"+ file)
if "yes" in stream['enable_cinder'] and "yes" in stream['enable_heat'] and "yes" in stream['enable_horizon']:
   print "Service configuration verified"

print "Configuration in globals.yaml is correct."
