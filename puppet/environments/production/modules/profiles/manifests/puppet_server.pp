class profiles::puppet_server {
  include ::hiera
  include ::r10k
	
  ### To fix foreman reporting bug:  https://tickets.puppetlabs.com/browse/SERVER-17
  package  { 'libbcprov-java':
    ensure => 'present',
  }

  
  class { '::puppet': 
    server => true ,
    #server_version => '2.7.0-1puppetlabs1',
    #server_puppetserver_version => '2.7.0',
    hiera_config => '$codedir/hiera.yaml',
    splay => true,
    listen => true,
    autosign => true,
    show_diff => true,
    server_reports => 'foreman',
    server_passenger => false,
    server_jvm_min_heap_size => '1G',
    server_jvm_max_heap_size => '1G',
    server_jvm_extra_args    => '-XX:MaxPermSize=256m',
  }

  class {'foreman': 
    notify  => Service['apache2']
  }
  include foreman_proxy



  File {
    owner => 'puppet',
    group => 'puppet',
  }

  file { ['/var/lib/puppet/.ssh/','/var/lib/puppet/r10k/']:
    ensure => directory,
    mode   => 'u=rwx',
  }

  $sshkeys = hiera_hash('sshkeys')

  unless empty($sshkeys) {
    create_resources('file', $sshkeys)
  }

  # $deploykeys = hiera_hash('deploykeys')

  # unless empty($deploykeys) {
  #  create_resources('git_deploy_key', $deploykeys)
  # }

  sshkey {'gitlab-01.example.com':
    ensure => present,
    type   => 'ssh-rsa',
    target => '/var/lib/puppet/.ssh/known_hosts',
    key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDLQ3enal5gvYyCUiHtBuEFi8EbA2RgWDBnoByeJ7Z9anSek7SY2tNaU5je9MfZLQ0Y9uNcFK2jliLlrUfPKwBouguhoZFt0Df80UN+OKA5CZQ4sOtmPB5mD2ylF3TqIbYqKYDeFSQssGyaIQyqPQh1enAZF6Udln6kQyyFoxtCYEWayxqGC4PgujMnu5nRhAJWE4WPOWbbvkjvMcsG4aR1brJj9uY+wnpaf7MgBARhJHXklnKZuY+1r0tiTs5KUAC8ptaGRjsFFxrk/EAJ0AlN3Qqn2CGR3OXft9SZWiGh2V0AoTWW+RoFeyCAgX7tFV+Y3heMfi6ogjAl7KELiLtF'
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
    require => Class['::r10k::webhook::config'],
  }
}
