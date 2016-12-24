Deploying Kolla on 100 node - Validation
========================================
Intro
------

This document summarizes my overall experience of deploying Openstack Kolla on 100 Node cluster, do's and dont's and overall results.

Environment
-----------

The cluster consists of both Dell and Lenovo bare metal servers. 
__Dell Server Specification:__
__RAM:__ 256GB
__VCPUs:__ 48 VCPU
__Disk:__ 600GB

__Lenovo Server Specification:__
__RAM:__ 256GB
__VCPUs:__ 48 VCPU
__Disk:__ 600GB

__Node Distribution:__
__Controller Nodes:__ 5
__Compute Nodes:__ 45
__Network Nodes:__ 15
__Storage Nodes:__ 20
__Monitoring Nodes:__ 15

Deployment Experience:
----------------------

#### Step 1: PXE Booting Server
This step involves performing all the operation performed in:
[1-osic-provisioning.md](https://github.com/osic/ref-impl-kolla/blob/master/documents/1-osic-provisioning.md). This included creating host file for all 100 nodes and PXE booting using cobbler. 
__Approx. time taken: 2 hours 15 mins.__ 

__Do's and Dont's:__ 
1. Do make sure that the ethernet interfaces of each server matches the server type. 
2. Do not reboot the server without doing `cobbler sync`.
3. Do not reboot the server without creating cobbler system profile.
4. Do make sure that there is a DHCP entry of the server corresponds to the correct MAC address in case the server doesnt PXE boot.

#### Step 2: Deploy Kolla
Perform all the operations listed in [2-osic-inventory-docker-registry.md](https://github.com/osic/ref-impl-kolla/blob/master/documents/2-osic-inventory-docker-registry.md) for creation of docker registry and [3-osic-deploy-kolla.md](https://github.com/osic/ref-impl-kolla/blob/master/documents/3-osic-deploy-kolla.md) for deploying kolla.

__Approx. time taken for creating docker registry:  6 mins__
__Approx. time taken for preparing target host: 10 mins__
__Approx time taken for Building Kolla images and pushing into docker registry: 13 mins__
__Approx time taken for Deploying Kolla: 4 hours__ 

__Total time: 4 hours 29 mins__

Do's and Dont's:
1. Do make sure that you reboot the server when kernel gets updated.
2. Do make sure you are able to ssh as root into target host from deployment host before starting kolla deployment.
3. Do not run cinder and swift before running bootstrap server.


Overall Results:
----------------
Due to prebuilt docker images for almost all services, deploying kolla is fast, simple and straightforward.

Total Time: 6 hours 45 mins
---------------------------
