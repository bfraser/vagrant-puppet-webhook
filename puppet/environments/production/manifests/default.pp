node /gitlab-\d+/ {
  include ::roles::version_control_server
}

node /puppetmaster-\d+/ {
  include ::roles::configuration_management_server
}
