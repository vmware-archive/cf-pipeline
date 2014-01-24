include_recipe 'apt'

include_recipe 'cf-jenkins::gvm'
include_recipe 'cf_pipeline::ruby'
include_recipe 'cf_pipeline::packages'

include_recipe 'cf_pipeline::pipeline_scripts'

include_recipe 'cf-jenkins::jenkins_base'
include_recipe 'cf_pipeline::ssh'
include_recipe 'cf_pipeline::jenkins_config'
include_recipe 'cf_pipeline::disable_nginx_default_site'
include_recipe 'cf_pipeline::pipelines'
include_recipe 'cf_pipeline::jenkins_plugins'
