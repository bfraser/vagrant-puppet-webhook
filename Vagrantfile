# -*- mode: ruby -*-
# vi: set ft=ruby :

# Require YAML module
require 'yaml'

# Load custom settings
settings = YAML.load_file('custom.yaml')

components = %w(gitlab puppetmaster)

Vagrant.configure(2) do |config|
  # Automatically manage host entries (requires 'vagrant-hostmanager' plugin)
  config.hostmanager.enabled = true

  components.each do |component|
    next component unless settings[component]['enabled']

    (1..settings[component]['nodes']).each do |i|
      hostname = "#{component}-%02d" % i

      config.vm.define hostname do |node|
        node.vm.box = 'base' # This will get overridden later
        node.vm.hostname = "#{hostname}.example.com"

        # Settings for VirtualBox provider
        node.vm.provider :virtualbox do |virtualbox, override|
          virtualbox.cpus = settings[component]['cpus']
          virtualbox.memory = settings[component]['memory']

          override.vm.box = settings[component]['image']
          config.vm.network "private_network", ip: settings[component]['ip']
        end

        # Settings for libvirt provider (requires 'vagrant-libvirt' plugin)
        node.vm.provider :libvirt do |libvirt, override|
          libvirt.cpus = settings[component]['cpus']
          libvirt.memory = settings[component]['memory']

          override.vm.box = settings[component]['image']
          override.nfs.functional = settings['libvirt']['nfs']
        end

        # Settings for AWS provider (requires 'vagrant-aws' plugin)
        node.vm.provider :aws do |aws, override|
          aws.access_key_id = settings['aws']['key']
          aws.secret_access_key = settings['aws']['secret']
          aws.keypair_name = settings['aws']['keypair']

          aws.ami = settings[component]['image']
          aws.instance_type = settings[component]['machine_type']
          aws.region = settings['aws']['region']
          aws.subnet_id = settings['aws']['subnet_id']
          aws.security_groups = settings['aws']['security_group']
          aws.associate_public_ip = settings['aws']['associate_public_ip']
          aws.user_data = "#!/bin/bash\nhostname #{hostname}\necho #{hostname} > /etc/hostname"

          # The base box, usually 'dummy'. Add using the following command:
          # vagrant box add dummy https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box
          override.vm.box = 'dummy'
          override.ssh.username = settings['ssh']['username']
          override.ssh.private_key_path = settings['ssh']['private_key_path']
          override.nfs.functional = false # vm.network calls don't work with this plugin
        end

        # Settings for GCE provider (requires 'vagrant-google' plugin)
        node.vm.provider :google do |google, override|
          google.google_project_id = settings['google']['project_id']
          google.google_client_email = settings['google']['client_email']
          google.google_json_key_location = settings['google']['json_key_location']

          google.name = "#{hostname}"
          google.image = settings[component]['image']
          google.machine_type = settings[component]['machine_type']

          # The base box, usually 'gce'. Add using the following command:
          # vagrant box add gce https://github.com/mitchellh/vagrant-google/raw/master/google.box
          override.vm.box = 'gce'
          override.ssh.username = settings['ssh']['username']
          override.ssh.private_key_path = settings['ssh']['private_key_path']
        end

        # Install Puppet modules (needs 'vagrant-r10k' and 'puppet' plugins)
        node.r10k.puppet_dir = 'puppet'
        node.r10k.puppetfile_path = 'puppet/Puppetfile'
        node.r10k.module_path = 'puppet/vendor'

        # Install Puppet (requires 'vagrant-puppet-install' plugin)
        node.puppet_install.puppet_version = settings['puppet']['version']

        # Provision with Puppet
        node.vm.provision :puppet do |puppet|
          puppet.manifests_path = 'puppet/manifests'
          puppet.manifest_file = 'default.pp'
          puppet.module_path = ['puppet/modules', 'puppet/vendor']
          puppet.hiera_config_path = 'puppet/hiera.yaml'
          puppet.working_directory = '/tmp/vagrant-puppet'
        end
      end
    end
  end
end
