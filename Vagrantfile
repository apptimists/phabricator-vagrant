# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  # Box
  config.vm.box = "ubuntu/trusty64"

  # SSH Agent Forwarding
  config.ssh.forward_agent = true

  config.vm.hostname = "phabricator.apptimists.com"

  # Private Network
  config.vm.network :private_network, ip: "192.168.50.12"

  # Provisioning
  config.vm.provision :shell, :path => "provision.sh"
end
