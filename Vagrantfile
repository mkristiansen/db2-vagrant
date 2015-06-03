# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

# Configuration parameters
ram = 2048                            # Ram in MB for each VM
secondaryStorage = 80                 # Size in GB for the secondary virtual HDD
privateNetworkIp = "10.10.10.50"      # IP for the private network between VMs
ENV['VAGRANT_DEFAULT_PROVIDER'] = 'virtualbox'

# Do not edit below this line
# --------------------------------------------------------------
privateSubnet = privateNetworkIp.split(".")[0...3].join(".")
privateStartingIp = privateNetworkIp.split(".")[3].to_i

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # Use vagrant-vbguest if the plugin is installed. Choose whether to update VirtualBox Guest Additions.
  if Vagrant.has_plugin?("vagrant-vbguest")  
    config.vbguest.auto_update = false
  end

  # Use vaggrant-cachier if the plugin is installed. Configure cached packages to be shared between instances of the same base box.
  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :box
  end

  config.vm.box = "chef/centos-6.6"
  config.vm.box_url = "https://vagrantcloud.com/chef/boxes/centos-6.6"

  config.vm.provider :parallels do |p, override|
      override.vm.box = "parallels/centos-6.5"
  end

  config.vm.define "db2-express" do |master|
    #master.vm.network :public_network
    master.vm.network :private_network, ip: "#{privateSubnet}.#{privateStartingIp}"
    master.vm.hostname = "db2-express"

    master.vm.provider "vmware_fusion" do |v|
      v.vmx["memsize"]  = "#{ram}"
    end
    
    master.vm.provider :parallels do |p|
      p.name = "db2-express"
      p.memory = ram
      
      file_to_disk = File.realpath( "." ).to_s + "/" + p.name + "_secondary_hdd"
      if ARGV[0] == "up" 
        if ! Dir.exist?(file_to_disk) 
          p.customize ['set', :id, '--device-add', 'hdd', '--iface', 'sata','--image', file_to_disk, '--size', "#{secondaryStorage * 1024}"]
        end
      end

      if ARGV[0] == "destroy" && Dir.exists?(file_to_disk)
         Dir.foreach(file_to_disk) {|f| fn = File.join(file_to_disk, f); File.delete(fn) if f != '.' && f != '..'}
         Dir.delete(file_to_disk)
      end
    end

    master.vm.provider :virtualbox do |v|
      v.name = "db2-express"
      v.customize ["modifyvm", :id, "--memory", "#{ram}"]
      file_to_disk = File.realpath( "." ).to_s + "/" + v.name + "_secondary_hdd.vdi"
      if ARGV[0] == "up" && ! File.exist?(file_to_disk)
        v.customize ['storagectl', :id, '--add', 'sata', '--name', 'SATA', '--portcount', 2, '--hostiocache', 'on']
        v.customize ['createhd', '--filename', file_to_disk, '--format', 'VDI', '--size', "#{secondaryStorage * 1024}"]
        v.customize ['storageattach', :id, '--storagectl', 'SATA', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', file_to_disk]
      end
    end

    master.vm.provision :shell, :path => "provision_for_mount_disk.sh"
    master.vm.provision :shell, :path => "db2.sh"
  end
end