# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  config.vm.define "jessie-box_Buzz7" do |sp|
    sp.vm.box = "debian/contrib-jessie64"
    sp.vm.network "forwarded_port", guest: 80, host: 80, auto_correct: true
    sp.vm.network "forwarded_port", guest: 443, host: 443, auto_correct: true
    sp.vm.network "forwarded_port", guest: 3306, host: 3306, auto_correct: true
    sp.vm.network "forwarded_port", guest: 8080, host: 8080, auto_correct: true
    sp.vm.network "forwarded_port", guest: 27017, host: 27017, auto_correct: true
    sp.vm.synced_folder "../", "/vagrant", type: "virtualbox"

    sp.vm.provider "virtualbox" do |vb|
      vb.memory = 8192
      vb.cpus = 4
      vb.name = "Buzz7"
    end

    sp.vm.provision "shell", :path => "lamp.sh"
  # sp.vm.provision "shell", :path => "lapp.sh"
  
    if Vagrant.has_plugin?("vagrant-cachier")
    # Configure cached packages to be shared between instances of the same base box.
    # More info on http://fgrehm.viewdocs.io/vagrant-cachier/usage
      sp.cache.scope = :box
    end
  end
end
