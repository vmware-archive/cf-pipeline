package 'libxml2-dev'
package 'libxslt-dev'

node['cf_pipeline']['packages'].each {|name| package name}
