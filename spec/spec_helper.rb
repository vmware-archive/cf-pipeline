require 'chefspec'
require 'chefspec/librarian'

PROJECT_ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..'))
$LOAD_PATH << File.join(PROJECT_ROOT, 'lib')

Dir.glob(File.join(PROJECT_ROOT, 'spec', 'support', '*.rb')).each do |support_file|
  require support_file
end

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.order = 'random' # Run specs in random order to surface order dependencies.

  ### ChefSpec ###
  config.platform = 'ubuntu'
  config.version = '12.04'

  config.include(CustomChefSpecMatchers)

  config.cookbook_path = File.join(PROJECT_ROOT, 'cookbooks')

  config.after(:suite) do
    # http://stackoverflow.com/a/18923622
    suite_failed = RSpec.world.filtered_examples.values.flatten.select {|e| e.exception}.any?

    puts(%q<
 __
/  \   It looks like your specs are failing!
|  |
@  @   RSpec is configured to automatically run `librarian-chef install`
|| ||  but it is possible that there is a .librarian/chef/config file
|| ||  clobbering your $LIBRARIAN_CHEF_PATH).
|\_/|
\___/      -- Love, Clippy
>
    ) if suite_failed
  end
end
