class noerdgresql {
    Class["noerdbase"] -> Class["noerdgresql"]

    exec { 'compile_enUS_locale':
        command                    => "localedef -f UTF-8 -i en_US en_US.UTF-8 && locale-gen en_US"
    }

    class { 'postgresql::server':
        package_name               => 'postgresql-9.5',
        package_ensure             => latest,
        listen_addresses           => '*',
        service_manage             => true,
        service_restart_on_change  => true,
        ip_mask_allow_all_users    => '0.0.0.0/0',
        require                    => Exec['compile_enUS_locale']
    }

    class { 'postgresql::client':
        package_name               => 'postgresql-client-9.5',
        package_ensure             => latest,
        require                    => Exec['compile_enUS_locale']
    }

    class { 'postgresql::server::contrib':
        package_name               => 'postgresql-contrib-9.5',
        package_ensure             => latest,
        require                    => Exec['compile_enUS_locale']
    }

    postgresql::server::pg_hba_rule { 'Open PostgreSQL for phoenix-web':
        type                       => 'host',
        database                   => 'all',
        user                       => 'all',
        address                    => "$::web_host/24",
        auth_method                => 'trust',
    }

    postgresql::server::role { 'vagrant':
        password_hash              => postgresql_password('vagrant', $::default_password),
        superuser                  => true,
        createdb                   => true,
        createrole                 => true,
    }

    $config_values = {
        'max_connections' => 250,
        'shared_buffers'  => '128MB',
        'lc_messages'     => 'en_US.UTF-8',
        'lc_monetary'     => 'en_US.UTF-8',
        'lc_numeric'      => 'en_US.UTF-8',
        'lc_time'         => 'en_US.UTF-8'
    }

    each($config_values) |$key, $value| {
        postgresql::server::config_entry { $key:
            value => $value
        }
    }
}
