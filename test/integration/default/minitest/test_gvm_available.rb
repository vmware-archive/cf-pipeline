require 'minitest/autorun'

describe 'GVM' do
  it 'provides go 1.2' do
    `/bin/bash -c 'source /etc/profile.d/gvm.sh; gvm use 1.2 && go version | grep 1.2'`
    $?.success?.must_equal true
  end
end
