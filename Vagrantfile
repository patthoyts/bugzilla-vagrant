# -*- mode: ruby -*-
# vi: set ft=ruby :
#

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ubuntu/trusty64"
  config.vm.network "forwarded_port", id: "http", guest: 80, host: 8080

  config.vm.provider "virtualbox" do |v|
    v.gui = false
    v.memory = "1024"
  end

  # If you have a local proxy (eg: privoxy), redirect the guest to use it
  if Vagrant.has_plugin?("vagrant-proxyconf")
    if ENV["http_proxy"]
      config.proxy.http = "http://10.0.2.2:3128"
      config.proxy.https = "http://10.0.2.2:3128"
      config.proxy.no_proxy = "localhost,127.0.0.1,10.0.2.2"
    end
  end

  # disable chef and puppet as we are not using these from the base box
  config.vm.provision :shell, :path => 'scripts/disable-chef.sh'
  config.vm.provision :shell, :path => 'scripts/disable-chef.sh'
  # install bugzilla.
  config.vm.provision :shell, :path => 'scripts/install-bugzilla.sh'
end
