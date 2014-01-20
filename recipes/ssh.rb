directory ::File.join(node['jenkins']['server']['home'], '.ssh') do
  owner node['jenkins']['server']['user']
  group node['jenkins']['server']['user']
  mode 0700
end

file ::File.join(node['jenkins']['server']['home'], '.ssh', 'id_rsa') do
  owner node['jenkins']['server']['user']
  group node['jenkins']['server']['user']
  mode 0600
  content node['cf_pipeline']['ssh']['private_key']
  not_if { node['cf_pipeline']['ssh']['private_key'].nil? }
end

file ::File.join(node['jenkins']['server']['home'], '.ssh', 'id_rsa.pub') do
  owner node['jenkins']['server']['user']
  group node['jenkins']['server']['user']
  mode 0644
  content node['cf_pipeline']['ssh']['public_key']
  not_if { node['cf_pipeline']['ssh']['public_key'].nil? }
end

file '/etc/ssh/ssh_known_hosts' do
  owner 'root'
  group 'root'
  mode 0644
  content(node['cf_pipeline']['ssh']['known_hosts'].join("\n") + "\n")
end
