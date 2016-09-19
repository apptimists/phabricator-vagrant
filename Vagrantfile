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

  config.vm.hostname = "phabricator.example.org"
  config.hostsupdater.aliases = ["cdn.example.org"]
  # Hostnames

  # Private Network
  config.vm.network :private_network, ip: "192.168.50.12"

  # Provisioning
  config.vm.provision "provision", type: "shell", :path => "provision.sh", args: [
    "pass@word1", # MySQL password
    "phabricator.example.org", # Server name
    "cdn.example.org", # Server alias
    "phabricator@example.org", # Server admin
    "phabricator@example.org", # Mail address
    "example.org", # Mail domain
    "phabricator", # Mail reply prefix
    "example.org", # Mail reply domain
    "mail.example.org", # SMTP host
    "phabricator", # SMTP user
    "pass@word1", # SMTP password
    "mail.example.org", # POP3 settings
    "phabricator", # POP3 user
    "pass@word1" # POP3 password
  ]

  config.vm.provision "no-tty-fix", type: "shell", inline: "sed -i '/tty/!s/mesg n/tty -s \\&\\& mesg n/' /root/.profile"
end
