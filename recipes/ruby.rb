include_recipe 'chef_rubies'

bash 'remove system rake gem' do
  code 'source /usr/local/share/chruby/chruby.sh && chruby 1.9.3 && gem uninstall rake --all --ignore-dependencies --executables'
end
