include_recipe 'cf-jenkins::gvm'
include_recipe 'chef_rubies'

# Minimal recipes to get Jenkins running
include_recipe 'cf-jenkins::jenkins_base'

# Able to specify pipelines by supplying Git, etc. info
include_recipe 'cf_pipeline::pipelines'

# Install only the plugins needed for pipeline steps
include_recipe 'cf-jenkins::pipeline_jenkins_plugins'
