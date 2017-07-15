# -*- mode: ruby -*-
# # vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "debian/contrib-jessie64"

  config.vm.provider :virtualbox do |v|

    v.memory = 1024

    for vol in ['1', '2', '3'] do
      disk_file = File.absolute_path("./.vboxhdd/extradisk#{vol}.vdi")
      if not File.exists?(disk_file)
        v.customize ['createhd', '--filename', disk_file, '--size', 128]
        v.customize ['storageattach', :id, '--storagectl', 'SATA Controller', '--port', vol, '--device', 0, '--type', 'hdd', '--medium', disk_file]
      end
    end

  end

  config.vm.provision :shell, :inline => "sudo /bin/bash /vagrant/provision.sh 2>&1 | tee /tmp/provision.log"
end
