Exec {
    path => [
        "/usr/local/sbin",
        "/usr/local/bin",
        "/usr/sbin",
        "/usr/bin",
        "/sbin",
        "/bin"
    ]
}

node 'phoenix-web' {
    include noerdbase
    include noerdweb
    include noerdphp
    include noerdproxy
    include noerdmysqlclient
}

node 'phoenix-db' {
    include noerdbase
    include noerdmysql
    include noerdmysqlclient
    include noerdlastic
}
