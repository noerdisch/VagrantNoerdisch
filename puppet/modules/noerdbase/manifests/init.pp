class noerdbase {
    class { "apt":
        purge => {
            'sources.list'   => true,
            'sources.list.d' => true
        }
    }

    $install_packages = [
        "vim",
        "git",
        "tig",
        "ant",
        "npm",
        "htop",
        "ruby",
        "unzip",
        "nodejs",
        "golang",
        "erlang",
        "telnet",
        "dnsmasq",
        "ruby-dev",
        "apparmor",
        "symlinks",
        "memcached",
        "python2.7",
        "virtualenv",
        "libyaml-dev",
        "redis-server",
        "python2.7-dev",
        "docker-engine",
        "openjdk-8-jre",
        "openjdk-8-jdk",
        "libsqlite3-dev",
        "graphicsmagick",
        "build-essential",
    ]

    $install_rubygems = [
        "jsonpp",
        "compass"
    ]

    sysctl { 'vm.swappiness':                 value => '2' }
    sysctl { 'fs.aio-max-nr':                 value => '10000000' }
    sysctl { 'fs.file-max':                   value => '262144' }
    sysctl { 'net.ipv4.tcp_max_syn_backlog':  value => '4096' }
    sysctl { 'net.ipv4.tcp_synack_retries':   value => '1' }
    sysctl { 'net.ipv4.tcp_fin_timeout':      value => '30' }
    sysctl { 'net.ipv4.tcp_keepalive_probes': value => '5' }
    sysctl { 'net.core.netdev_max_backlog':   value => '4096' }
    sysctl { 'net.core.somaxconn':            value => '65536' }

    class { 'locales':
        default_locale  => 'en_US.UTF-8',
        locales         => ['en_US.UTF-8 UTF-8', 'de_DE.UTF-8 UTF-8'],
    }

    tidy { "clean_default_motd":
        path            => "/etc/update-motd.d",
        recurse         => true,
        matches         => '*',
    }

    tidy { "clean_default_cron":
        path            => "/etc/cron.daily",
        recurse         => true,
        matches         => [
            "apt-compat",
            "update-notifier-common"
        ]
    }

    tidy { "clean_default_apt_config":
        path            => "/etc/apt/apt.conf.d",
        recurse         => true,
        matches         => [
            "10periodic",
            "99update-notifier"
        ]
    }

    class { 'timezone':
        timezone        => 'Europe/Berlin',
        autoupgrade     => true
    }

    exec { "apt-update":
        command         => "apt-get update"
    }

    exec { "get_mailhog_sendmail":
        command         => "go get github.com/mailhog/mhsendmail",
        environment     => [
            "GOPATH=/usr/local/"
        ],
        require         => Package["golang"],
        creates         => "/usr/local/bin/mhsendmail"
    }

    apt::source { "mirrors.ubuntu.com-${lsbdistcodename}":
        location        => 'mirror://mirrors.ubuntu.com/mirrors.txt',
        repos           => 'main universe multiverse restricted',
        notify          => Exec['apt-update']
    }

    apt::source { "mirrors.ubuntu.com-${lsbdistcodename}-security":
        location        => 'mirror://mirrors.ubuntu.com/mirrors.txt',
        repos           => 'main universe multiverse restricted',
        release         => "${lsbdistcodename}-security",
        notify          => Exec['apt-update']
    }

    apt::source { "mirrors.ubuntu.com-${lsbdistcodename}-updates":
        location        => 'mirror://mirrors.ubuntu.com/mirrors.txt',
        repos           => 'main universe multiverse restricted',
        release         => "${lsbdistcodename}-updates",
        notify          => Exec['apt-update']
    }

    apt::source { "mirrors.ubuntu.com-${lsbdistcodename}-backports":
        location        => 'mirror://mirrors.ubuntu.com/mirrors.txt',
        repos           => 'main universe multiverse restricted',
        release         => "${lsbdistcodename}-backports",
        notify          => Exec['apt-update']
    }

    apt::source { 'erlang':
        comment         => 'Erlang/OTP Vendor Packages',
        location        => 'https://packages.erlang-solutions.com/ubuntu',
        release         => 'xenial',
        repos           => 'contrib',
        pin             => '1000',
        key             => {
            id            => '434975BD900CCBE4F7EE1B1ED208507CA14F4FCA',
            source        => 'https://packages.erlang-solutions.com/ubuntu/erlang_solutions.asc',
        },
        include         => {
            src           => false,
            deb           => true,
        },
        notify          => Exec['apt-update']
    }

    apt::source { 'docker':
        comment         => 'Docker Vendor Packages',
        location        => 'https://apt.dockerproject.org/repo',
        release         => 'ubuntu-xenial',
        repos           => 'main',
        pin             => '1000',
        key             => {
            id            => '58118E89F3A912897C070ADBF76221572C52609D',
            source        => 'https://apt.dockerproject.org/gpg',
        },
        include         => {
            src           => false,
            deb           => true,
        },
        notify          => Exec['apt-update']
    }

    package { $install_packages:
        ensure          => "latest",
        require         => [
            Exec["apt-update"],
            Apt::Source["docker"],
            Apt::Source["erlang"],
            Apt::Source["mirrors.ubuntu.com-${lsbdistcodename}"],
            Apt::Source["mirrors.ubuntu.com-${lsbdistcodename}-security"],
            Apt::Source["mirrors.ubuntu.com-${lsbdistcodename}-updates"],
            Apt::Source["mirrors.ubuntu.com-${lsbdistcodename}-backports"]
        ]
    }

    package { [ "cachefilesd" ]:
        ensure          => "absent",
    }

    package { $install_rubygems:
        provider        => "gem",
        ensure          => "latest",
        require         => [
            Package["ruby-dev"],
            Package["libsqlite3-dev"],
            Package["build-essential"]
        ]
    }

    file { "/etc/motd":
        ensure          => file,
        content         => template("noerdbase/motd.erb")
    }

    file { "/usr/local/bin/node":
        ensure          => 'link',
        target          => '/usr/bin/nodejs',
        require         => Package['nodejs']
    }

    file { "/etc/hosts":
        ensure          => file,
        content         => template("noerdbase/hosts.erb")
    }

    file { "/home/vagrant/.profile":
        ensure           => present,
        content          => template("noerdbase/dot_profile.erb"),
        owner            => 'vagrant',
        group            => 'vagrant',
        mode             => '0600'
    }

    file { "/etc/security/limits.conf":
        ensure          => file,
        content         => template("noerdbase/limits.conf.erb")
    }

    file { "/etc/dnsmasq.conf":
        ensure     => file,
        content    => template("noerdbase/dnsmasq.conf.erb"),
        mode       => "0644",
        require    => Package["dnsmasq"],
        notify     => Service["dnsmasq"]
    }

    user { "vagrant":
        groups          => "docker",
        shell           => "/bin/bash",
        require         => Package["docker-engine"]
    }

    service { "dnsmasq":
        ensure     => running,
        hasrestart => true,
        hasstatus  => true,
        subscribe  => [
            File["/etc/dnsmasq.conf"]
        ]
    }
}
