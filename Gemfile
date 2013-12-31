source 'https://rubygems.org'

gem 'librarian-chef'
gem 'foodcritic'

group :test do
  # TODO: point at the next version of the Gem > 3.0.2 when it is released
  # (Gem update requested in issue https://github.com/sethvargo/chefspec/issues/276 )
  gem 'chefspec', '~> 3.1.2'

  # Normally builder is installed via chef_gem, but we execute some unit tests that touch that code path
  gem 'builder'
end

group :integration do
  gem 'test-kitchen'
  gem 'kitchen-vagrant', '~> 0.11'
end
