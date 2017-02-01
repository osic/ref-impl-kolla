OSIC Kolla Deployment Process
=============================

Overview
---------

Consider the scenario where you have a number of bare metal servers and you want to build your own OpenStack cloud on top of them. The purpose of this repository is to help you achieve that goal and perform the OpenStack installation in a simple and efficient manner. 

__Note: These steps need to be performed on the deployment host.__

__If you have provisioned your own nodes and are in `osic-prep` container exit from `osic-prep` container and log in to the deployment host. If not provided by the operator, you will find the Deployment host IP from `hosts` file created in previous steps,__

__If you are deploying Openstack on nodes that are already provisioned, you will find your information about target and deployment hosts from `/etc/hosts` file present in your deployment host. __

The process consists of two parts:


# [Part 1: Creating Docker Registry.](https://github.com/osic/ref-impl-kolla/blob/master/documents/ease-of-use/1-osic-create-docker-registry.md)
# [Part 2: Deploy Openstack Kolla.](https://github.com/osic/ref-impl-kolla/blob/master/documents/ease-of-use/2-osic-deploy-kolla.md)
