# Vagrant box for nœrdisch Development

This is the general purpose development stack used at [nœrdisch - digital solutions](https://www.noerdisch.de/) for legacy projects and fun & pleasure.

The GitHub version published here is known internally as v2.3.0 without some customer-specific, confidential modules.

The stack is created in two machines. One box for anything web-related, the other box for anything database related. Both boxes have about 50 GB disk space (used for operating system, databases & stuff like that, excluding your projects), will use 25% of total RAM on the host system in total (e.g. 4 GB divided into two slices per 2 GB if you got 16 Gigs on your host) and all CPU cores of your system which should be suitable for most projects you run in this box.

If you're running 8 GB RAM or less on the host system the machines will get 1 GB of RAM each to provide a stable environment for your projects. That might be an issue for you in case you're running 4 GB or less on the host system.

Both boxes get `/opt/transfer` mounted via NFS (`_transfer` on your local disk) to make both boxes able to share data if needed.

These boxes are named after [Phoenix](https://en.wikipedia.org/wiki/Phoenix_%28spacecraft%29) which visited [Mars](https://de.wikipedia.org/wiki/Mars_%28Planet%29) back in 2008 - even though it does fit the german idiom "Phönix aus der Asche" too.

## Get it up & running

### Make sure you run at least

* a Git client
* [Vagrant](http://vagrantup.com/) 1.8.x
    * Virtualbox Additions Plugin: `vagrant plugin install vagrant-vbguest`
* [Virtualbox](http://www.virtualbox.org/) 5.0.x / 5.1.x

#### Supported host operating systems:

* Mac OS X 10.11.x
* Linux (CentOS 7.x / Ubuntu 16.04 LTS) is going to be added "soon"
* **never** to be added: any Windows Version

Any other combination _might_ work, but is neither tested nor supported by [nœrdisch - digital solutions](https://www.noerdisch.de/). The repository is provided as-is without warranty.

## How To

Clone this repository

    git clone <the repository url> ~/VagrantNoerdisch

Change to the cloned repository

    cd ~/VagrantNoerdisch

Install Plugin vbguest which keeps your boxes Guest Additions in sync with your Virtualbox version:

    vagrant plugin install vagrant-vbguest

Boot up the virtual box:

    vagrant up --provision

If you are using a Mac (well .. you are since it's a requirement to run this box) you have to enter your password of your Mac while the boot up. This is caused by the NFS mounting process that requires root access (done by `sudo`) to modify your local `/etc/exports`.

Both boxes get one static IP addresses (web: **192.168.50.50**, database: **192.168.50.51**) which are only accessible from your local computer. You do need to be connected to the internet however while provisioning the box.

Please run a single `vagrant reload --provision` after initial setup. This is due to adjusting things like open files limits & stuff like that.

## virtual Hosts / Services

| Service           | Hostname                          | Document Root                | IP/Port            | Protocol |
|-------------------|-----------------------------------|------------------------------|--------------------|----------|
| Wildcard          | *project*.local.noerdisch.net     | `/var/www/$project/Web/`     | 192.168.50.50:80   | HTTP     |
| Symfony2 Wildcard | *project*.local-sf2.noerdisch.net | `/var/www/sf2/$project/web/` | 192.168.50.50:80   | HTTP     |
| Elasticsearch     | elasticsearch.local.noerdisch.net | *none*                       | 192.168.50.50:9200 | HTTP     |
| MySQL             | db.local.noerdisch.net            | *none*                       | 192.168.50.51:3306 | MySQL    |

### PHP Versions

Based on the awesome [PPA](https://launchpad.net/~ondrej/+archive/ubuntu/php/+index) of [Ondřej Surý](https://deb.sury.org/#donate) this box does provide a couple of different PHP versions.

The default engine used is PHP 5.6. To test your application with some different Version just prefix the project URL with one of the following values:

| PHP Version   | Prefix   | Dotfile  |
|---------------|----------|----------|
| 5.5           | `php55.` | `.php55` |
| 5.6 (default) | `php56.` | `.php56` |
| 7.0           | `php70.` | `.php70` |
| 7.1           | `php71.` | `.php71` |

Otherwise you can place a file in `/var/www/$project` to pin a project to a specific version of PHP (see Dotfile-Column above). That file may be empty, as it's checked for existance only. So to pin a project (e.g. `test`) to PHP 5.5 run the following command on the web-host (`vagrant ssh phoenix-web` => `touch /var/www/test/.php55`). This will make nginx always pass requests to PHP 5.5.

PHP 7.1.0 is available as aplha-3 as per time of writing this. So expect that things might break while using this engine. There might not even be all PHP modules be in place for PHP 7.1 yet.

When working on CLI you should specify your PHP Version in detail (e.g. `php5.5 /my/awesome/script.php`) to prevent falling back to some default (which is PHP 5.6).

### Sites

All Sites are running under the `local.noerdisch.net` Domain which is setup on our (read: [nœrdisch - digital solutions](https://www.noerdisch.de/)) internal/external DNS Servers. You should be able to use this box wherever you've access to some DNS Server which does resolve correctly.

#### TYPO3 CMS / Flow / other applications

There's a vHost in place which makes you able to run (almost) any PHP based application you want. Just put your application into a folder (called `$project` in the list above/below) underneath `/var/www` (`_vHosts` Folder within this repository on your Local Disk) and make sure your document root is living in its subfolder `Web` (note the uppercase "W"). In case of trouble: symlink (`ln -s`) is your friend - e.g. for running Laravel or some application which does expect a folder named `public`, `html` or anything else.

Your project will be available at: `http://project.local.noerdisch.net`

##### Note on TYPO3 CMS

This box has been optimized a little to make it work with TYPO3s multi-tree capability (probably other CMS can do this as well) and hit the correct page-tree as configured in TYPO3 CMS backend. You can use your actual production URLs as a part of the request URL using the following pattern:

```
$engine .  $productionurl  . $project .local.noerdisch.net
 php55  . www.noerdisch.de .  noerd   .local.noerdisch.net
```

The box (better: nginx) does set `HTTP_HOST` & `SERVER_NAME` to the same values to prevent falling into issues with TYPO3s trusted host patterns. Please keep that in mind and secure your installation accordingly!

#### Symfony2

There's another wildcard vHost configured to run Symfony2 projects. Symfony2 project are able to live underneath the folder `/var/www/sf2/$project` (`_vHosts/sf2` folder within this repository on your Local Disk - created during `vagrant provision`).

This is another virtual host on the list as the default rewrite with which you're able to run virtually anything which rewrites its requests to `/index.php` won't fit for Symfony2 projects. We need `/app.php` respectively `/app_dev.php` here and a lowercase "web" as document root (which _does_ matter on case sensitive filesystems).

Your project will be available at: `http://project.local-sf2.noerdisch.net`

## Note on MySQL

The stack comes with a MySQL database server installed on the host `phoenix-db`. Instead of typing some IP or long hostnames in your application you can use the shorthandle `db` as database host from within your applications. The Hostname `db` does resolve to `192.168.50.51`.

You can however use `127.0.0.1:3306` as database server too to provide some sort of "quick-start". Haproxy is in place to handle this and pass traffic from the web- to the database-box.

### MySQL Credentials

| Server      | Username   | Password  | Remarks                                        |
|-------------|------------|-----------|------------------------------------------------|
| phoenix-web | *vagrant*  | jolt200mg | your applications should use those credentials |
| phoenix-db  | *root*     | jolt200mg | used for maintenance & stuff                   |

You can use the database user *vagrant* to access the MySQL server from your host using tools like [Sequel Pro](http://www.sequelpro.com/) or [MySQL Workbench](https://www.mysql.de/products/workbench/) using the host `local.noerdisch.net` so you won't need something like phpMyAdmin or Adminer.

## Note on Elasticsearch

The box comes with 2 Elasticsearch nodes running as a cluster (Clustername is `noerdlastic_2x_local`, the version is pinned to 2.3.4 which marks the current stable 2.x Release).

To access Plugins (see below for a list of installed ones) or use Elasticsearch from your computer in other ways there's a proxy-configuration on haproxy in place which makes you able to use the host http://elasticsearch.local.noerdisch.net:9200.

## Currently installed Packages

The box is using Ubuntu 16.04. The base box image is kept up to date on a spare-time base. The box is custom built at [nœrdisch - digital solutions](https://www.noerdisch.de/) for our needs and originally based upon [ffuenf/vagrant-boxes](https://github.com/ffuenf/vagrant-boxes).

* MySQL Server 5.7 (credentials: see above)
* Memcached
* Redis Server
* [nginx](https://nginx.org)
* [PHP](https://www.php.net) (5.5, 5.6, 7.0, 7.1) as CLI & FastCGI server, "batteries included" ([PPA](https://launchpad.net/~ondrej/+archive/ubuntu/php/+index))
* [MailHog](https://github.com/mailhog/MailHog/) docker container accessible at http://local.noerdisch.net:8025
* [haproxy](http://www.haproxy.org/) to pass traffic from web to database box ([stats](http://local.noerdisch.net:1936/haproxy))
* [Elasticsearch](https://www.elastic.co/products/elasticsearch) 2.x vendor package (accessible at http://elasticsearch.local.noerdisch.net:9200/)
    * Plugin: [kopf](http://elasticsearch.local.noerdisch.net:9200/_plugin/kopf) ([source](https://github.com/lmenezes/elasticsearch-kopf))
    * Plugin: [head](http://elasticsearch.local.noerdisch.net:9200/_plugin/head) ([source](https://github.com/mobz/elasticsearch-head))
* [Docker Engine](https://www.docker.com/) ([vendor package](https://docs.docker.com/engine/installation/linux/ubuntulinux/))
* some other tools including:
    * git
    * tig
    * ant
    * htop
    * mytop
    * erlang
    * golang
    * dnsmasq
    * nodejs & npm
    * graphicsmagick
    * java 1.8 (jre & jdk)

## We are hiring

If you'd like to work full-time with this box in a clean, friendly & professional environment: We're looking for Symfony2 developers & Frontend / UI developers with experience in RWD and JavaScript (ES6).

If you're interested get in touch with us: [nœrdisch - digital solutions](https://www.noerdisch.de/)

## License

This Vagrant box is licensed under the permissive [MIT license](http://opensource.org/licenses/MIT) - have fun with it!
