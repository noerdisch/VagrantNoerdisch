class noerdproxy {
    Class["noerdbase"] -> Class["noerdproxy"]

    include apt

    apt::ppa { 'ppa:vbernat/haproxy-1.7': }

    class { 'haproxy':
        merge_options      => true,
        package_ensure     => 'latest',
        require            => [
            Apt::Ppa['ppa:vbernat/haproxy-1.7']
        ]
    }

    haproxy::listen { 'mysql3306':
        collect_exported   => false,
        ipaddress          => '0.0.0.0',
        ports              => '3306',
        mode               => 'tcp',
        options            => {
            'timeout client' => '30m',
            'timeout server' => '30m',
            'option'         => [
                'mysql-check user haproxy',
                'tcpka',
            ]
        }
    }

    haproxy::listen { 'elasticsearch9200':
        collect_exported   => false,
        ipaddress          => '0.0.0.0',
        ports              => '9200',
        mode               => 'http',
        options            => {
            option => [
                'forwardfor',
                'httpchk GET / HTTP/1.0'
            ],
            'http-check' => 'expect string You\ Know,\ for\ Search',
        }
    }

    haproxy::balancermember { 'phoenix_db':
        server_names       => 'phoenix_db',
        listening_service  => 'mysql3306',
        ipaddresses        => $::db_host,
        ports              => '3306',
        options            => 'check'
    }

    haproxy::balancermember { 'noerdsearch01':
        server_names       => 'noerdsearch01',
        listening_service  => 'elasticsearch9200',
        ipaddresses        => $::db_host,
        ports              => '19200',
        options            => 'check'
    }

    haproxy::balancermember { 'noerdsearch02':
        server_names       => 'noerdsearch02',
        listening_service  => 'elasticsearch9200',
        ipaddresses        => $::db_host,
        ports              => '19201',
        options            => 'check'
    }

    haproxy::listen { 'stats':
        collect_exported   => false,
        ipaddress          => '0.0.0.0',
        ports              => '1936',
        mode               => 'http',
        options            => {
            'stats' => [
                'enable',
                'show-legends',
                'show-node',
                'uri /haproxy'
            ]
        }
    }
}
