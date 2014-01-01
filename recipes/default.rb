include_recipe 'cf-jenkins::gvm'
include_recipe 'chef_rubies'

include_recipe 'cf-jenkins::jenkins_base'
include_recipe 'cf_pipeline::pipelines'
include_recipe 'cf_pipeline::pipeline_jenkins_plugins'
