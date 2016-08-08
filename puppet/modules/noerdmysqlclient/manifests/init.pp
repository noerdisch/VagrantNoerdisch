class noerdmysqlclient {
    Class["noerdbase"] -> Class["noerdmysqlclient"]

    exec { 'aptget_update_before_mysql_client':
        command          => "apt-get update",
    }

    package { "mytop":
        ensure           => latest,
        require          => Exec["aptget_update_before_mysql_client"],
    }

    class { 'mysql::server::mysqltuner': }

    class { 'mysql::client':
        require          => Exec["aptget_update_before_mysql_client"],
        package_name     => 'mysql-client',
        package_ensure   => latest,
    }

    file { "/home/vagrant/.my.cnf":
        ensure           => present,
        content          => template("noerdmysqlclient/dot_my.cnf.erb"),
        owner            => 'vagrant',
        group            => 'vagrant',
        mode             => '0600'
    }
}
