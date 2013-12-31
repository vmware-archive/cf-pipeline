require 'minitest/autorun'

describe 'Ruby' do
  it 'provides version 1.9.3-p484' do
    `/bin/bash -c 'source /usr/local/share/chruby/chruby.sh; chruby 1.9.3 && ruby -v | grep "ruby 1.9.3p484"'`
    $?.success?.must_equal true
  end
end
