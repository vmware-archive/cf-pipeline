require 'minitest/autorun'

describe 'SSH known hosts' do
  it 'knows about GitHub' do
    output = `ssh -T git@github.com 2>&1`
    assert_match(/#{Regexp.escape('Permission denied (publickey).')}/, output)
    refute_match(/#{Regexp.escape('Host key verification failed.')}/, output)
  end
end
