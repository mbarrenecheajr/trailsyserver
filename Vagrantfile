# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.
  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box_url = "http://files.vagrantup.com/precise64.box"

  config.vm.define "app" do |app|
    app.vm.box = "precise64"
    app.vm.network :forwarded_port, host: 8888, guest: 80
    app.vm.provision :puppet do |puppet|
      puppet.module_path = "puppet/modules"
      puppet.manifests_path = "puppet/manifests"
      puppet.manifest_file  = "app.pp"
      puppet.options = ["--verbose"]
    end    
  end
end
