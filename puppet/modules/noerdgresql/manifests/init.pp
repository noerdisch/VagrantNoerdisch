class noerdgresql {
    Class["noerdbase"] -> Class["noerdgresql"]

    class { 'postgresql::server':
        package_name               => 'postgresql-9.5',
        package_ensure             => latest,
        listen_addresses           => '*',
        service_manage             => true,
        service_restart_on_change  => true,
        ip_mask_allow_all_users    => '0.0.0.0/0',
        #ip_mask_deny_postgres_user => '172.16.0.0/16'
    }

    class { 'postgresql::client':
        package_name               => 'postgresql-client-9.5',
        package_ensure             => latest,
    }

    class { 'postgresql::server::contrib':
        package_name               => 'postgresql-contrib-9.5',
        package_ensure             => latest
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
