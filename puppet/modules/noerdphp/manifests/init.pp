class noerdphp {
    Class["noerdbase"] -> Class["noerdphp"]

    include apt

    apt::ppa { 'ppa:ondrej/php':
        notify     => Exec["aptget_update_after_ppa"],
    }

    exec { "aptget_update_after_ppa":
        command    => "apt-get update",
        require    => Apt::Ppa["ppa:ondrej/php"],
        refreshonly => true
    }

    $install_common_php_packages = [
        "php-apcu",
        "php-ssh2",
        "php-http",
        "php-yaml",
        "php-redis",
        "php-xdebug",
        "php-imagick",
        "php-memcache",
    ]

    package { $install_common_php_packages:
        ensure     => "latest",
        require    => [
            Apt::Ppa["ppa:ondrej/php"],
            Exec["aptget_update_after_ppa"]
        ]
    }

    $versions = {
        "5.5" => "55",
        "5.6" => "56",
        "7.0" => "70",
        "7.1" => "71"
    }

    $default_version = "5.6"

    each($versions) |$version_package, $version_symlink| {

        $install_service_version_packages = [
            "php${version_package}-fpm",
            "php${version_package}-cli",
            "php${version_package}-dev",
        ]

        $install_version_packages = [
            "php${version_package}-curl",
            "php${version_package}-gd",
            "php${version_package}-intl",
            "php${version_package}-ldap",
            "php${version_package}-readline",
            "php${version_package}-mysql",
            "php${version_package}-pgsql",
            "php${version_package}-xmlrpc",
            "php${version_package}-xsl",
            "php${version_package}-json",
            "php${version_package}-bz2",
            "php${version_package}-mbstring",
            "php${version_package}-mcrypt",
            "php${version_package}-soap",
            "php${version_package}-xml",
            "php${version_package}-zip"
        ]

        package { $install_service_version_packages:
            ensure     => latest,
            require    => [
                Apt::Ppa["ppa:ondrej/php"],
                Exec["aptget_update_after_ppa"]
            ]
        }

        package { $install_version_packages:
            ensure     => latest,
            require    => [
                Apt::Ppa["ppa:ondrej/php"],
                Exec["aptget_update_after_ppa"],
                Package[$install_service_version_packages],
            ],
            notify     => Service["php${version_package}-fpm"]
        }

        file { "/etc/php/${version_package}/fpm/pool.d/www.conf":
            ensure     => file,
            content    => template("noerdphp/php-${version_package}/www.conf.erb"),
            require    => [
                Package["php${version_package}-fpm"],
            ]
        }

        $phpini_common = [
            "/etc/php/${version_package}/fpm/conf.d/zz-noerdisch-common.ini",
            "/etc/php/${version_package}/cli/conf.d/zz-noerdisch-common.ini"
        ]

        file { $phpini_common:
            ensure     => file,
            content    => template("noerdphp/noerdisch-common.ini.erb"),
            require    => [
                Package["php${version_package}-fpm"]
            ]
        }

        $phpini_version = [
            "/etc/php/${version_package}/fpm/conf.d/zzz-noerdisch-${version_package}.ini",
            "/etc/php/${version_package}/cli/conf.d/zzz-noerdisch-${version_package}.ini"
        ]

        file { $phpini_version:
            ensure     => file,
            content    => template("noerdphp/php-${version_package}/version.ini.erb"),
            require    => [
                Package["php${version_package}-fpm"]
            ]
        }

        file { "/usr/local/bin/php${version_symlink}":
            ensure     => link,
            target     => "/usr/bin/php${version_package}",
            require    => Package["php${version_package}-cli"]
        }

        service { "php${version_package}-fpm":
            ensure     => running,
            enable     => true,
            hasrestart => true,
            hasstatus  => true,
            require    => [
                Package["php${version_package}-fpm"]
            ],
            subscribe  => [
                Package[$install_common_php_packages],

                Package[$install_version_packages],
                Package[$install_service_version_packages],

                File["/etc/php/${version_package}/fpm/pool.d/www.conf"],
                File["/etc/php/${version_package}/fpm/conf.d/zz-noerdisch-common.ini"],
                File["/etc/php/${version_package}/fpm/conf.d/zzz-noerdisch-${version_package}.ini"]
            ]
        }
    }

    file { "/usr/local/bin/php":
        ensure     => link,
        target     => "/usr/bin/php${default_version}",
        require    => Package["php${default_version}-cli"]
    }
}
