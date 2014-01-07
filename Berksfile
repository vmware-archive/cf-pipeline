site :opscode

cookbook 'chef_rubies',
  git: 'https://github.com/ichilton/chef_rubies'

cookbook 'chef_chruby_install',
  git: 'https://github.com/ichilton/chef_chruby_install'

cookbook 'selfsigned_certificate', github: 'cgravier/selfsigned_certificate', ref: 'c5c6fc9073e0164010a5c33b43ec79f7d6245d05'

cookbook 'cf-jenkins',
  git: 'https://github.com/pivotal-cf-experimental/cf-jenkins'

# Workaround for topological sort failure ["windows", "powershell"],
# see https://github.com/applicationsonline/librarian/issues/159
cookbook 'windows',
  :git => 'https://github.com/SimpleFinance/chef-windows.git'

cookbook 'cf_pipeline', path: '.'
