require 'chefspec'

module CustomChefSpecMatchers
  def associate_aws_elastic_ip(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_elastic_ip, :associate, resource_name)
  end

  def attach_aws_ebs_volume(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_ebs_volume, :attach, resource_name)
  end

  def update_jenkins_job(job_name)
    ChefSpec::Matchers::ResourceMatcher.new(:jenkins_job, :update, job_name)
  end

  def install_jenkins_plugin(plugin_name)
    ChefSpec::Matchers::ResourceMatcher.new(:jenkins_plugin, :install, plugin_name)
  end
end
