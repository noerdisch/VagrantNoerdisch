class noerdlastic {
    Class["noerdbase"] -> Class["noerdlastic"]

    class { 'elasticsearch':
        manage_repo   => true,
        repo_version  => '2.x',
        package_pin   => true,
        version       => '2.3.5',
        autoupgrade   => true,
        status        => 'enabled',
        config        => { 'cluster.name' => 'noerdlastic_2x_local' },
        init_defaults => { 'ES_HEAP_SIZE' => '128m' },
        datadir       => '/var/lib/elasticsearch/',
        restart_on_change => true,
    }

    elasticsearch::instance { 'noerdsearch01':
        config        => {
            'node.name'                        => 'noerdsearch01',
            'network.host'                     => '127.0.0.1',
            'http.host'                        => '0.0.0.0',
            'http.port'                        => '19200',
            'transport.tcp.port'               => '19300',
            'gateway.expected_nodes'           => 2,
            'discovery.zen.ping.unicast.hosts' => ['127.0.0.1:19301'],
            'script.engine.groovy.inline.aggs' => 'on',
            'cluster.routing.allocation.disk.threshold_enabled' => false,
        }
    }

    elasticsearch::instance { 'noerdsearch02':
        config        => {
            'node.name'                        => 'noerdsearch02',
            'network.host'                     => '127.0.0.1',
            'http.host'                        => '0.0.0.0',
            'http.port'                        => '19201',
            'transport.tcp.port'               => '19301',
            'gateway.expected_nodes'           => 2,
            'discovery.zen.ping.unicast.hosts' => ['127.0.0.1:19300'],
            'script.engine.groovy.inline.aggs' => 'on',
            'cluster.routing.allocation.disk.threshold_enabled' => false,
        }
    }

    Elasticsearch::Plugin { instances => ['noerdsearch01', 'noerdsearch02'] }
    elasticsearch::plugin { 'mobz/elasticsearch-head': }
    elasticsearch::plugin { 'lmenezes/elasticsearch-kopf/2.0': }
}
