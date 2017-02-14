# -*- mode: ruby -*-
# vi: set ft=ruby :

# Load our custom configuration and prepare some global variables
require 'yaml'
cwd       = File.dirname(File.expand_path(__FILE__))
ext_conf  = YAML.load_file("#{cwd}/build.yaml")
_opts     = Hash[ext_conf.select {|hash| hash["option"] == "general"}[0]]
machines  = ext_conf.select {|hash| hash["option"] == "machine"}


VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # Map NFS uid/gid to current user. This can be used to create a
  # user inside the VM with matching uid/gid which makes file access
  # a lot easier.
  #config.nfs.map_uid = Process.uid
  #config.nfs.map_gid = Process.gid

  # This section should help speed up provisioning by caching packages locally,
  # because Gerhard does not want to believe me that our link is dog slow.

  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :box
    config.cache.synced_folder_opts = {
      type: :nfs,
      mount_options: ['rw', 'vers=3', 'tcp', 'nolock']
    }
    # For more information please check http://docs.vagrantup.com/v2/synced-folders/basic_usage.html
  end

  # DNS for boxes
  if Vagrant.has_plugin?("vagrant-dns")
    config.dns.tld = "#{_opts["domain"]}.#{_opts["tld"]}"
  end
  
  machines.each do |m|

    if !m["enabled"]
      next
    end
    # Prepends the VM name with our project so that we can have multiple
    # projects with the same VM name
    _vmName = "#{_opts["project"]}-#{m["name"]}"

    config.vm.define m["name"], primary: m["primary"] do |srv|

      srv.vm.box = m["box"]
      if ! m["box_url"].nil?
        srv.vm.box_url = m["box_url"]
      end
      srv.ssh.insert_key = true
      srv.vm.synced_folder ".", "/vagrant", disabled: true

      srv.vm.provider :virtualbox do |v|
        v.name = _vmName
        v.linked_clone = m["linked_clone"]
        v.memory = m["memory"]
        v.cpus = m["cpus"]
        v.gui = m["gui"]
        # Always connect ttyS0 to an output file
        v.customize [ "modifyvm", :id, "--uartmode1", "file", File.join(Dir.pwd, "#{m["hostname"]}-console.log") ]
        m["vm_mods"].each do |_copts|
          v.customize ["modifyvm", :id, _copts["option"], _copts["value"]]
        end
      end

      srv.vm.hostname = m["hostname"]
      srv.vm.network :private_network, ip: m["private_ip"]

      if m["provision"]
        # Ansible provisioner.
        srv.vm.provision "ansible" do |ansible|
          ansible.playbook = "provisioning/ansible/playbook.yml" 
          ansible.sudo = true
        end
      end
    end
  end
end
