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
  config.vm.provision :shell, :path => "provision.sh", env: {
    "MYSQL_PASSWORD" => "pass@word1",
    "SERVER_NAME" => "phabricator.apptimists.com",
    "SERVER_ALIAS" => "cdn.apptimists.com",
    "SERVER_ADMIN" => "phabricator@apptimists.com",
    "MAIL_ADDRESS" => "phabricator@apptimists.com",
    "MAIL_DOMAIN" => "apptimists.com",
    "MAIL_REPLY_PREFIX" => "phabricator",
    "MAIL_REPLY_DOMAIN" => "apptimists.com",
    "SMTP_HOST" => "mail.apptimists.com",
    "SMTP_USER" => "phabricator",
    "SMTP_PASSWORD" => "pass@word1",
    "POP3_HOST" => "mail.apptimists.com",
    "POP3_USER" => "phabricator",
    "POP3_PASSWORD" => "pass@word1"
  }
end
