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

    $versions = [
        "5.5",
        "5.6",
        "7.0",
        "7.1"
    ]

    $defaultVersion = "5.6"

    each($versions) |$version| {

        $install_service_version_packages = [
            "php$version-fpm",
            "php$version-cli",
            "php$version-dev",
        ]

        $install_version_packages = [
            "php$version-curl",
            "php$version-gd",
            "php$version-intl",
            "php$version-ldap",
            "php$version-readline",
            "php$version-mysql",
            "php$version-pgsql",
            "php$version-xmlrpc",
            "php$version-xsl",
            "php$version-json",
            "php$version-bz2",
            "php$version-mbstring",
            "php$version-mcrypt",
            "php$version-soap",
            "php$version-xml",
            "php$version-zip"
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
            notify     => Service["php$version-fpm"]
        }

        file { "/etc/php/$version/fpm/pool.d/www.conf":
            ensure     => file,
            content    => template("noerdphp/php-$version/www.conf.erb"),
            require    => [
                Package["php$version-fpm"],
            ]
        }

        $phpini_common = [
            "/etc/php/$version/fpm/conf.d/zz-noerdisch-common.ini",
            "/etc/php/$version/cli/conf.d/zz-noerdisch-common.ini"
        ]

        file { $phpini_common:
            ensure     => file,
            content    => template("noerdphp/noerdisch-common.ini.erb"),
            require    => [
                Package["php$version-fpm"]
            ]
        }

        $phpini_version = [
            "/etc/php/$version/fpm/conf.d/zzz-noerdisch-$version.ini",
            "/etc/php/$version/cli/conf.d/zzz-noerdisch-$version.ini"
        ]

        file { $phpini_version:
            ensure     => file,
            content    => template("noerdphp/php-$version/version.ini.erb"),
            require    => [
                Package["php$version-fpm"]
            ]
        }

        service { "php$version-fpm":
            ensure     => running,
            enable     => true,
            hasrestart => true,
            hasstatus  => true,
            require    => [
                Package["php$version-fpm"]
            ],
            subscribe  => [
                Package[$install_common_php_packages],

                Package[$install_version_packages],
                Package[$install_service_version_packages],

                File["/etc/php/$version/fpm/pool.d/www.conf"],
                File["/etc/php/$version/fpm/conf.d/zz-noerdisch-common.ini"],
                File["/etc/php/$version/fpm/conf.d/zzz-noerdisch-$version.ini"]
            ]
        }
    }

    file { "/usr/local/bin/php":
        ensure     => link,
        target     => "/usr/bin/php$defaultVersion",
        require    => Package["php$defaultVersion-cli"]
    }
}
