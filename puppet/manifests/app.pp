$as_vagrant   = "sudo -u vagrant -H bash -l -c"
$home         = '/home/vagrant'

Exec {
  path => ['/usr/sbin', '/usr/bin', '/sbin', '/bin']
}

# --- Preinstall Stage ---------------------------------------------------------

stage { 'preinstall':
  before => Stage['main']
}

class apt_get_update {
  exec { 'apt-get -y update':
    unless => "test -e ${home}/.rvm"
  }
}

class { 'apt_get_update':
  stage => preinstall
}

package { ['sqlite3', 'libsqlite3-dev', 'curl', 'libpq-dev', 'git-core', 'nodejs', "libgdal-ruby", 'ntp', 'libyaml-dev', 'libxml2', 'libxml2-dev', 'libxslt1-dev']:
  ensure => installed;
}

# --- Ruby and Rails ---------------------------------------------------------------------

exec { 'install_rvm':
  command => "${as_vagrant} 'curl -L https://get.rvm.io | bash -s stable'",
  creates => "${home}/.rvm",
  require => Package['curl']
}

exec { 'install_ruby':
  command => "${as_vagrant} '${home}/.rvm/bin/rvm install 2.0.0 --autolibs=enabled'",
  creates => "${home}/.rvm/bin/ruby",
  timeout => 600,
  require => [ Package['libyaml-dev'], Exec['install_rvm'] ]
}

exec { 'set_default_ruby':
  command => "${as_vagrant} '${home}/.rvm/bin/rvm --fuzzy alias create default 2.0.0 && ${home}/.rvm/bin/rvm use default'",
  require => Exec['install_ruby']
}

exec { 'install_bundler':
  command => "${as_vagrant} 'cd /vagrant/; gem install bundler --no-rdoc --no-ri'",
  creates => "${home}/.rvm/bin/bundle",
  require => Exec['install_ruby']
}

exec { "bundle_install":
  command => "${as_vagrant} 'cd /vagrant/; bundle install'",
  require => Exec["install_ruby"]
}


# Nginx
class {"nginx": }

nginx::resource::upstream { 'thin':
  ensure  => "present",
  members => ["0.0.0.0:3000"]
}

nginx::resource::vhost { 'project-vhost':
  ensure      => "present",
  index_files => [],
  proxy       => "http://thin",
  proxy_set_header => ["Host \$http_host"],
}

# #Get rid of Nginx Defaults.
# file { "/etc/nginx/conf.d/default.conf":
#   require => Package["nginx"],
#   ensure => "absent",
#   notify => Service ["nginx"],
# }

#PostgreSQL
class { "postgresql::server":
  listen_addresses => "*"
}

postgresql::server::db { 'trails_db':
  user     => 'vagrant',
  password => postgresql_password('vagrant', 'pwd'),
}

include postgresql::server::postgis

postgresql::server::pg_hba_rule { 'allow application network to access app database':
  description => "Open up postgresql for access from 192.168.50.5/24",
  type => 'host',
  database => 'trails_db',
  user => 'vagrant',
  address => 'localhost',
  auth_method => 'md5',
}
