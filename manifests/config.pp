# Internal: Prepare your system for MySQL.
#
# Examples
#
#   include mysql::config

class mysql::config(
  $ensure = undef,

  $configdir = undef,
  $bindir = undef,
  $globalconfigprefix = undef,
  $datadir = undef,
  $executable = undef,

  $logdir = undef,

  $host = undef,
  $port = undef,
  $socket = undef,
  $user = undef,
) {

  File {
    ensure => $ensure,
    owner  => $user,
  }

  $userconfdir = "/Users/${::boxen_user}/.boxen/config/mysql"

  file {
    [
      $configdir,
      $datadir,
      $logdir,
      $userconfdir
    ]:
      ensure => directory ;

    "${configdir}/my.cnf":
      content => template('mysql/my.cnf.erb'),
      notify  => Service['mysql'] ;

    "${globalconfigprefix}/etc/my-default.cnf":
      ensure => link,
      target => "${configdir}/my.cnf"
  }

  ->
  exec { 'init-mysql-db':
    command  => "${bindir}/mysqld \
      --verbose \
      --initialize-insecure \
      --basedir=${globalconfigprefix}/opt/mysql \
      --datadir=${datadir} \
      --tmpdir=/tmp",
    creates  => "${datadir}/mysql",
    provider => shell,
    user     => $user,
  }

  ->
  boxen::env_script { 'mysql':
    ensure   => $ensure,
    content  => template('mysql/env.sh.erb'),
    priority => 'higher',
  }

  if $::osfamily == 'Darwin' {
    file {
    "${boxen::config::envdir}/mysql.sh":
      ensure => absent ;

    "${globalconfigprefix}/var/mysql":
      ensure  => absent,
      force   => true,
      recurse => true ;

    "${globalconfigprefix}/etc/my.cnf":
      ensure  => link,
      target  => "${configdir}/my.cnf" ;
    }
  }
}
