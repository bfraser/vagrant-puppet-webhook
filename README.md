# Vagrant environment to test webhook for deploying Puppet control repository using GitLab and r10k

## Table of Contents

1. [Overview](#overview)
2. [Setting up the Environment](#setting-up-the-environment)
  * [Requirements](#requirements)
3. [Custom Configuration](#custom-configuration)
4. [Bringing up the Environment](#bringing-up-the-environment)
5. [TODO](#todo)
6. [Development](#development)

## Overview

This repository contains a ```Vagrantfile``` and code necessary to provision a GitLab server and Puppet master, for testing a webhook to trigger r10k deploy.

This build is based on Ubuntu 16.04 images for both puppet/gitlab and puppet 4.8.2 using Foreman as a front end.

## Setting up the Environment

### Requirements

1. Operating system: Linux, Mac OS X, Windows
2. [Vagrant](https://www.vagrantup.com/downloads.html) (TODO: determine minimum version required)
3. Vagrant compatible hypervisor / virtualization tool. Current choices include:
  * [VirtualBox](https://www.virtualbox.org/). Check installation instructions for your distribution.
  * [KVM](http://www.linux-kvm.org/page/Main_Page) + [libvirt](http://libvirt.org/): for Linux systems. Check installation instructions for your distribution. You will also need the [vagrant-libvirt](https://github.com/pradels/vagrant-libvirt#installation) plugin
  * Google Compute Engine (GCE): for provisioning in the cloud. You will need the [vagrant-google](https://github.com/mitchellh/vagrant-google) plugin
  * Amazon Web Services (AWS): for provisioning in the cloud. You will need the [vagrant-aws](https://github.com/mitchellh/vagrant-aws) - Installs plugin. Also need to run "vagrant box add base https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box" to create the base box for AMI launch.
4. Vagrant plugins:
  * [vagrant-hostmanager](https://github.com/smdahlen/vagrant-hostmanager) - automatically add entries to ```/etc/hosts``` for running VMs, permitting name resolution
  * [vagrant-puppet-install](https://github.com/petems/vagrant-puppet-install) - installs Puppet inside VMs so Vagrant's Puppet provisioner may be used
  * [vagrant-r10k](https://github.com/jantman/vagrant-r10k) - Installs Puppet modules using r10k, rather than having to store them in the project repository
  * puppet - so r10k can install modules, run ```vagrant plugin install puppet```

## Custom Configuration

The ```Vagrantfile``` in this repository makes use of a non-version controlled configuration file named ```custom.yaml``` which contains your local customizations including how many instances to provision, provider settings (including project names, keys/secrets), compute resources (CPU, memory), etc.

In future it may be possible for the configuration file to be generated automatically for you, but for now you may use the following example as a starting point:

```yaml
---
  # Configure stack here
  # ---
  # Note: 'image' examples include:
  #   'matjazp/ubuntu-trusty64' (libvirt)
  #   'puppetlabs/ubuntu-14.04-64-nocm' (virtualbox)
  #   'ami-ff427095' (AWS, https://cloud-images.ubuntu.com/locator/ec2/)
  #   'ubuntu-14-04' (Google)
  # Note: 'machine_type' examples include:
  #   't2.micro' (AWS, http://www.ec2instances.info/)
  #   'g1-small' (Google)
  # ---
  # GitLab: for on premise version control
  gitlab:
    enabled: true
    nodes: 1
    cpus: 2
    memory: 2048
    image: puppetlabs/ubuntu-16.04-64-nocm
    #image: matjazp/ubuntu-trusty64
    #image: ami-af5a4cc5
    #machine_type: t2.micro
  # Puppet: Puppet master, for r10k webhook
  puppetmaster:
    enabled: true
    nodes: 1
    cpus: 1
    memory: 512
    image: puppetlabs/ubuntu-16.04-64-nocm
    #image: matjazp/ubuntu-trusty64
    #image: ami-af5a4cc5
    #machine_type: t2.micro

  # Puppet provisioner settings
  puppet:
    version: 4.8.2

  # AWS provider settings
  aws:
    key: # Enter your AWS key
    secret: # Enter your AWS secret key
    keypair: # Enter the name of your EC2 keypair
    region: us-east-1
    subnet_id: # Must exist
    security_group: # Must exist and permit inbound SSH
    associate_public_ip: true # Associate a public IP with each instance

  # Google provider settings
  google:
    client_email: # Enter your GCE service account email
    json_key_location: client_secrets.json
    project_id: # Enter your GCE project ID

  # Libvirt provider settings
  libvirt:
    nfs: false

  ssh:
    private_key_path: ~/.ssh/id_rsa
    username: # Enter your username here

```

## Bringing up the Environment

In order to bring up the environment for the first time, it will be necessary to do the following:

1. Ensure you have satisfied all of the [requirements](#requirements)
2. Clone the repository and change into the directory, if you haven't already done so
3. Create the ```custom.yaml``` file manually, using the [example above](#custom-configuration) if necessary. Each of the provider blocks are necessary, even if you aren't using them. Vagrant won't run if they aren't there
4. Create the ```puppet/vendor``` directory manually.
```
mkdir -p puppet/environments/production/vendor
```

This last step is necessary since empty directories cannot be tracked in Git, and the ```vagrant-r10k``` plugin will remove the directory's contents, making it impossible to have a placeholder file such as ```README.md``` or ```.gitignore```. If you have a solution so this step is not required, please contribute :)

Once you have completed these steps, you should be able to bring up the environment by running Vagrant as follows:
```
vagrant up --no-parallel
```

If you would like to use a specific provider (such as libvirt), use the ```--provider``` parameter:
```
vagrant up --provider libvirt --no-parallel
```

It is possible that one of the machines may fail to provision cleanly on first run. If this happens, and / or the failure prevented other machines from being brought up, you can tell Vagrant to try again using a combination of the following commands:
```
vagrant provision [machine]
vagrant up --provider [provider] --no-parallel
```

If you omit a machine name from the provision command above, Vagrant will re-run the provisioner on all available machines. There should be no cost involved in doing so, other than time.

## TODO

1. Add support for other Vagrant providers, including VMware
2. Use ```hiera-eyaml``` for secrets
3. Make it possible to forward guest service ports to the host
4. Resolve provisioner errors so machines are provisioned cleanly on first run

## Development

If you would like to contribute to this repository, please submit a pull request.
