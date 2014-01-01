override['jenkins']['http_proxy'] = {
  'server_auth_method' => 'basic',
  'basic_auth_username' => node['cf_pipeline']['basic_auth_username'],
  'basic_auth_password' => node['cf_pipeline']['basic_auth_password'],
  'ssl' => {
    'enabled' => true,
    'redirect_http' => true,
    'cert_path' => '/var/lib/jenkins/ssl/server.crt',
    'key_path' => '/var/lib/jenkins/ssl/server.key',
  }
}
