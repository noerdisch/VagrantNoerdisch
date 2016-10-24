# -*- mode: ruby -*-
# vi: set ft=ruby :

BOX_VERSION = "20160809.1"
BOX_CHECKSUM = "f24966fd9d89401eb4b65b9ba99c91588c62a5d242ca63588266d27307ddb226"

HOST_DB = "192.168.50.51"
HOST_WEB = "192.168.50.50"

# Get host os type
host = RbConfig::CONFIG['host_os']

# Give VM 1/4 system memory & access to all cpu cores on the host
if host =~ /darwin/
    cpus = `sysctl -n hw.physicalcpu`.to_i
    # sysctl returns Bytes and we need to convert to MB
    mem = `sysctl -n hw.memsize`.to_i / 1024 / 1024 / 8
elsif host =~ /linux/
    cpus = `nproc`.to_i
    # meminfo shows KB and we need to convert to MB
    mem = `grep 'MemTotal' /proc/meminfo | sed -e 's/MemTotal://' -e 's/ kB//'`.to_i / 1024 / 8
else # sorry other folks, I can't help you
    cpus = 1
    mem = 1024
end

MEMORY = mem.to_i
CPUS = cpus.to_i

# Enforce lower bound of memory to 1024 MB
if MEMORY < 1024
    MEMORY = 1024
end

Vagrant.configure("2") do |config|
    config.vm.box = "noerdisch/ubuntu-16.04/#{BOX_VERSION}"
    config.vm.box_url = "https://cdn.noerdisch.net/vagrant/images/ubuntu/16.04/#{BOX_VERSION}/ubuntu-16.04-server-amd64_virtualbox.box"
    config.vm.box_check_update = false
    config.vm.box_download_checksum = "#{BOX_CHECKSUM}"
    config.vm.box_download_checksum_type = "sha256"

    config.vm.define "phoenix-web", primary: true do |box|
        box.vm.network "private_network", ip: HOST_WEB
        box.vm.synced_folder "_vHosts", "/var/www",
            :nfs => true,
            :nfs_version => 3,
            :nfs_udp => false,
            :mount_options => [ 'rsize=32768', 'wsize=32768', 'vers=3', 'tcp', 'fsc', 'intr', 'nolock', 'noatime', 'nodiratime', 'retrans=3' ]
        box.vm.synced_folder "_transfer", "/opt/transfer",
            :nfs => true,
            :nfs_version => 3,
            :nfs_udp => false,
            :mount_options => [ 'rsize=32768', 'wsize=32768', 'vers=3', 'tcp', 'fsc', 'intr', 'nolock', 'noatime', 'nodiratime', 'retrans=3' ]
        box.vm.hostname = "phoenix-web"
        box.vm.provider "virtualbox" do |vb|
            vb.name      = "Noerdisch Development Stack (OpenSource Web)"
            vb.gui       = false
            vb.cpus      = CPUS.to_i
            vb.memory    = MEMORY.to_i

            vb.customize [ "modifyvm", :id, "--natdnshostresolver1", "on" ]
            vb.customize [ "modifyvm", :id, "--natdnsproxy1",        "on" ]
            vb.customize [ "modifyvm", :id, "--nictype1",        "virtio" ]
        end

        box.vm.provision "docker" do |docker|
            docker.run "mailhog", image: "mailhog/mailhog", daemonize: true, args: "--publish 127.0.0.1:1025:1025 --publish 0.0.0.0:8025:8025 --env MH_HOSTNAME=mail.local.noerdisch.net"
        end
    end

    config.vm.define "phoenix-db" do |box|
        box.vm.network "private_network", ip: HOST_DB
        box.vm.synced_folder "_transfer", "/opt/transfer",
            :nfs => true,
            :nfs_version => 3,
            :nfs_udp => false,
            :mount_options => [ 'rsize=32768', 'wsize=32768', 'vers=3', 'tcp', 'fsc', 'intr', 'nolock', 'noatime', 'nodiratime','retrans=3' ]
        box.vm.hostname = "phoenix-db"
        box.vm.provider "virtualbox" do |vb|
            vb.name      = "Noerdisch Development Stack (OpenSource DB)"
            vb.gui       = false
            vb.cpus      = CPUS.to_i
            vb.memory    = MEMORY.to_i

            vb.customize [ "modifyvm", :id, "--natdnshostresolver1", "on" ]
            vb.customize [ "modifyvm", :id, "--natdnsproxy1",        "on" ]
            vb.customize [ "modifyvm", :id, "--nictype1",        "virtio" ]
        end
    end

    config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"

    config.vm.provision :shell, :inline => "cp /vagrant/puppet/Puppetfile /etc/puppet"
    config.vm.provision :shell, :inline => "cd /etc/puppet && rm -rf /etc/puppet/modules && librarian-puppet install"
    config.vm.provision :shell, :inline => "while $(fuser /var/lib/dpkg/lock >/dev/null 2>&1) ; do echo 'waiting for dpkg lock release ...' ; sleep 1 ; done && ( sync; sync; sync; sleep 1; apt-get -qy update; )"

    config.vm.provision "puppet" do |puppet|
        puppet.facter = {
            "db_host"            => HOST_DB,
            "web_host"           => HOST_WEB,
            "default_password"   => "jolt200mg",
            "login_user"         => `echo $(echo $USER | head -c 1 | tr [a-z] [A-Z]; echo $USER | tail -c +2) | tr -d '\n'`
        }

        puppet.manifests_path    = "puppet/manifests"
        puppet.module_path       = "puppet/modules"
        puppet.hiera_config_path = "puppet/hiera.yaml"
        puppet.manifest_file     = "noerdsite.pp"
        puppet.options           = "--environment=local --parser=future"
    end
end
