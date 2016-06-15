# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"


Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

	config.vm.define "master" do |master|
	config.vm.synced_folder ".", "/vagrant", owner:"www-data", group:"www-data", mount_options:["dmode=775", "fmode=775"]
	config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"
	config.vm.provision :shell, :path => "phabricator-install.sh"
     	master.vm.box = "precise64"
	master.vm.hostname = "master"
     	master.vm.network "private_network", ip: "192.168.50.40"
		config.vm.provider "virtualbox" do |v|
  			v.name = "phabricator"
  			v.memory = 1024
  			v.cpus = 2
		end
	end

end





