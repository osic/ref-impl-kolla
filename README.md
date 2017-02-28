![alt text](https://01.org/sites/default/files/pictures/openstack04.png)

# OSIC Ease of Use guide
Welcome to the OSIC Cluster Ease of deployment guide repo. The purpose of this repo is to create the ease of use guide that will allow Operators/Enthusiasts in deploying Openstack in Multinode cluster in a simplistic and faster manner.

# What Problems does it solve ?
When it comes to deployment tool adoption, one of the key factor to consider is to have an easy to use deployment guide that customers can use to deploy Openstack. The demand for ease-of-use along with faster deployments are increasing. Customers are consolidating their server, storage and networking environments and are trying to get more functionality with less complexity. We at the OSIC Ops Team have validated Openstack using Kolla on a 100 Bare Metal node ([summary](https://github.com/osic/ref-impl-kolla/blob/master/documents/validation_kolla.md)) cluster using this guide.

# Repo Structure

The Repo contains the following folders: <br/>
1. Document: Contains Ease of Use deployment guide.<br/>
   |_ ease-of-use: Most updated deployment guide.<br/>
      |_ osic-provisoning.md: Describes Bare Metal provisioning.<br/>
      |_ Overview.md: Overview of Ease of Use deployment process.<br/>
      |_ 1-osic-create-docker-registry.md: Contains detailed steps to create docker registry on deployment host.<br/>
      |_ 2-osic-deploy-kolla.md: Contains steps to prepare your deployment host and deploy OpenStack services using Kolla.<br/>
2. Inventory: Contains sample Ansible host inventory files.<br/>
3. Playbooks: Contains playbooks used to prepare storage nodes, create swift partitions, create cinder volume groups, adding ssh signatures, configuring network interfaces for bare metal provisioning.<br/>
4. Scripts: Contains shell and python scripts for creating swift rings, generate ansible host file, polling bare metal servers during provisioning, configuring PXE IP on bare metal servers.<br/>

