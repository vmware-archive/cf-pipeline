require 'spec_helper'

describe 'cf_pipeline::ruby' do
  subject(:chef_run) do
    ChefSpec::Runner.new.converge(described_recipe)
  end

  before do
    Chef::Recipe.any_instance.stub(:include_recipe).with('chef_rubies').and_return(true)
  end

  it 'installs ruby via the chef_rubies cookbook' do
    Chef::Recipe.any_instance.should_receive(:include_recipe).with('chef_rubies').and_return(true)
    chef_run
  end

  it 'uninstalls the system rake gem, which would otherwise cause later problems with bundle package' do
    expect(chef_run).to run_bash('remove system rake gem').with(
      code: 'source /usr/local/share/chruby/chruby.sh && gem uninstall rake --all --ignore-dependencies --executables',
    )
  end
end
