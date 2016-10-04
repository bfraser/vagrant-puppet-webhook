class profiles::puppet_server {
  include ::foreman
  include ::hiera
  include ::r10k
  include ::puppet
  include ::ssh

  File {
    owner => 'puppet',
    group => 'puppet',
  }

  file { ['/var/lib/puppet/.ssh/','/var/lib/puppet/r10k/','/opt/puppetlabs/','/opt/puppetlabs/server/','/opt/puppetlabs/server/apps/','/opt/puppetlabs/server/apps/puppetserver']:
    ensure => directory,
    mode   => 'u=rwx',
  }

  exec { 'ssh-keyscan gitlab-01.example.com > /var/lib/puppet/.ssh/known_hosts':
    path   => '/usr/bin:/usr/sbin:/bin',
    require => File['/var/lib/puppet/.ssh/known_hosts']
  }


  file { '/var/lib/puppet/.ssh/known_hosts':
    ensure => present,
    mode   => '644',
  }

  $sshkeys = hiera_hash('sshkeys')

  unless empty($sshkeys) {
    create_resources('file', $sshkeys)
  }

  # $deploykeys = hiera_hash('deploykeys')

  # unless empty($deploykeys) {
  #  create_resources('git_deploy_key', $deploykeys)
  # }

  package { 'ruby2.0':
    provider => apt,
  }

  package { 'ruby2.0-dev':
    provider => apt,
  }


  class { '::r10k::webhook::config':
    protected       => false,
    enable_ssl      => false,
    use_mcollective => false,
    notify          => Service['webhook'],
  }

  class { '::r10k::webhook':
    user    => 'puppet',
    group   => 'puppet',
    require => [Class['::r10k::webhook::config'], Package['ruby2.0']]
  }
}
