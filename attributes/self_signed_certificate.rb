override['selfsigned_certificate'] = {
  'destination' => '/var/lib/jenkins/ssl/',
  'sslpassphrase' => node['cf_pipeline']['ssl_passphrase'],
  'country' => 'us',
  'state' => 'ca',
  'city' => 'sf',
  'orga' => 'cf',
  'depart' => 'eng',
  'cn' => 'cf-eng',
  'email' => 'ssl@example.com',
}

