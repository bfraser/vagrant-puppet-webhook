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

  file { '/var/lib/puppet/.ssh/known_hosts':
    ensure => present,
    mode   => '644',
    content => "gitlab-01.example.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBIsG7XCJP10buPQSOKQUCXwNvvYDux2gdkOAwxXUHk2N+02twzapGRUq2SuE/9/ks33zmpBAR/W/HRUvKvHNSDE=\n"
  }

  $sshkeys = hiera_hash('sshkeys')

  unless empty($sshkeys) {
    create_resources('file', $sshkeys)
  }

  # $deploykeys = hiera_hash('deploykeys')

  # unless empty($deploykeys) {
  #  create_resources('git_deploy_key', $deploykeys)
  # }


  class { '::r10k::webhook::config':
    protected       => false,
    enable_ssl      => false,
    use_mcollective => false,
    notify          => Service['webhook'],
  }

  class { '::r10k::webhook':
    user    => 'puppet',
    group   => 'puppet',
    require => Class['::r10k::webhook::config'],
  }
}
