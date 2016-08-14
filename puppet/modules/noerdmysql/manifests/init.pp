class noerdmysql {
    Class["noerdbase"] -> Class["noerdmysql"]

    $noerd_options = {
        'mysqld_safe' => {
            'socket'                => '/var/run/mysqld/mysqld.sock',
            'nice'                  => 0,
            'skip_log_error'        => 1,
            'syslog'                => 1,
        },
        'mysqld' => {
            'user'                  => 'mysql',
            'pid-file'              => '/var/run/mysqld/mysqld.pid',
            'socket'                => '/var/run/mysqld/mysqld.sock',
            'port'                  => 3306,
            'basedir'               => '/usr',
            'datadir'               => '/var/lib/mysql',
            'tmpdir'                => '/tmp',
            'lc-messages-dir'       => '/usr/share/mysql',
            'skip-external-locking' => 1,
            'bind-address'          => '0.0.0.0',
            'character-set-server'  => 'utf8mb4',
            'collation-server'      => 'utf8mb4_general_ci',
            'open_files_limit'      => 1024000,
            'max_connections'       => 500,
            'table_open_cache'      => 2048,
            'query_cache_limit'     => '4M',
            'query_cache_size'      => '32M',
            'max_allowed_packet'    => '256M',
            'sql_mode'              => 'NO_ENGINE_SUBSTITUTION',
            'default-storage-engine'         => 'INNODB',
            'innodb_file_per_table'          => 1,
            'innodb_buffer_pool_size'        => '128M',
            'innodb_flush_log_at_trx_commit' => 2,
            'innodb_log_file_size'           => '256M',
        }
    }

    exec { 'aptget_update_before_mysql':
        command          => "apt-get update",
    }

    mysql_user { 'vagrant@%':
        ensure           => 'present',
        password_hash    => '*28EBA18EDAA9EB1F895A2D43CE2A61CD902E955E' # jolt200mg
    }

    mysql_user { 'haproxy@%':
        ensure           => 'present',
    }

    mysql_grant { 'vagrant@%/*.*':
        ensure           => 'present',
        options          => ['GRANT'],
        privileges       => ['ALL'],
        table            => '*.*',
        user             => 'vagrant@%',
    }

    class { 'mysql::server':
        require          => Exec["aptget_update_before_mysql"],
        service_enabled  => true,
        service_manage   => true,
        restart          => true,
        package_name     => 'mysql-server',
        package_ensure   => latest,
        service_name     => 'mysql',
        config_file      => '/etc/mysql/my.cnf',
        includedir       => '/etc/mysql/noerd-conf.d',
        root_password    => $::default_password,
        override_options => $noerd_options,
        remove_default_accounts => true,
    }
}
