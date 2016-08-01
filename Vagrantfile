# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  # Box
  config.vm.box = "ubuntu/trusty64"

  # Box Configurations - more power!
  config.vm.provider :virtualbox do |v|
    v.customize ["modifyvm", :id, "--memory", 2048]
    v.customize ["modifyvm", :id, "--cpus", 2]
    v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    v.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
  end

  # SSH Agent Forwarding
  config.ssh.forward_agent = true

  config.vm.hostname = "phabricator.apptimists.com"
  config.hostsupdater.aliases = ["cdn.apptimists.com"]

  # Private Network
  config.vm.network :private_network, ip: "192.168.50.12"

  # Provisioning
  config.vm.provision :shell, :path => "provision.sh"
end
