class noerdweb {
    Class["noerdbase"] -> Class["noerdweb"]

    package { "nginx":
        ensure     => latest
    }

    file { ["/etc/nginx/conf.d", "/etc/nginx/sites", "/var/www/sf2" ]:
        ensure     => directory,
        require    => Package["nginx"]
    }

    file { "nginx_copy_certificates":
        path       => '/etc/nginx/ssl',
        ensure     => directory,
        source     => '/vagrant/puppet/modules/noerdweb/files/ssl',
        ignore     => '.DS_Store',
        owner      => 'root',
        group      => 'root',
        replace    => true,
        recurse    => remote,
        notify     => Service["nginx"]
    }

    file { "nginx_copy_additional_sites":
        path       => '/etc/nginx/sites.d',
        ensure     => directory,
        source     => '/vagrant/_nginx-sites.d/',
        ignore     => '.DS_Store',
        purge      => true,
        owner      => 'root',
        group      => 'root',
        replace    => true,
        recurse    => remote,
        notify     => Service["nginx"]
    }

    file { "/var/log/nginx/":
        ensure     => directory,
        owner      => "vagrant",
        group      => "vagrant"
    }

    file { ["/var/log/nginx/access.log", "/var/log/nginx/error.log"]:
        ensure     => file,
        owner      => "vagrant",
        group      => "vagrant"
    }

    exec { "ensure_nginx_log_permissions":
        command    => "chown -R vagrant:vagrant /var/log/nginx/*.log"
    }

    $nginx_configs = [
        "nginx.conf",

        "conf.d/fastcgi_params",
        "conf.d/fastcgi.conf",
        "conf.d/mime.types",
        "conf.d/upstreams.conf",

        "sites/wildcard.conf",
        "sites/wildcard-sf2.conf",
    ]

    each($nginx_configs) |$conf| {
        file { "/etc/nginx/${conf}":
            ensure     => file,
            content    => template("noerdweb/nginx/${conf}.erb"),
            require    => [
                Package["nginx"],

                File["/etc/nginx/conf.d"],
                File["/etc/nginx/sites"]
            ],
            notify     => [
                Service["nginx"]
            ]
        }
    }

    service { "nginx":
        ensure     => running,
        enable     => true,
        hasrestart => true,
        hasstatus  => true,
        subscribe  => [
            File["nginx_copy_certificates"],
            File["nginx_copy_additional_sites"],

            File["/etc/nginx/nginx.conf"],

            File["/etc/nginx/sites/wildcard.conf"],
            File["/etc/nginx/sites/wildcard-sf2.conf"],

            File["/etc/nginx/conf.d/mime.types"],
            File["/etc/nginx/conf.d/fastcgi.conf"],
            File["/etc/nginx/conf.d/fastcgi_params"],
            File["/etc/nginx/conf.d/upstreams.conf"],
        ]
    }
}
