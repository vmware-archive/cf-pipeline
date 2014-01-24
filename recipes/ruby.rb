include_recipe 'chef_rubies'

bash 'remove system rake gem' do
  code 'source /usr/local/share/chruby/chruby.sh && gem uninstall rake --all --ignore-dependencies --executables'
end
