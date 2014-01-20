require 'spec_helper'

describe 'cf_pipeline::ssh' do
  let(:public_key_content) { 'some public key data' }
  let(:private_key_content) { 'some private key data' }

  subject(:chef_run) do
    ChefSpec::Runner.new do |node|
      node.set['cf_pipeline']['ssh']['public_key'] = public_key_content
      node.set['cf_pipeline']['ssh']['private_key'] = private_key_content
      node.set['cf_pipeline']['ssh']['known_hosts'] = [
        'cvs.example.com ssh-rsa AAA',
        'git.example.com ssh-rsa BBB',
      ]

      node.set['jenkins']['server']['home'] = '/home/jenkins'
      node.set['jenkins']['server']['user'] = 'jenkins'
    end.converge(described_recipe)
  end

  it 'creates the .ssh directory' do
    expect(chef_run).to create_directory('/home/jenkins/.ssh').with(
      owner: 'jenkins',
      group: 'jenkins',
      mode: 0700
    )
  end

  it 'fills in the public key file' do
    expect(chef_run).to create_file('/home/jenkins/.ssh/id_rsa.pub').with(
      owner: 'jenkins',
      group: 'jenkins',
      mode: 0644,
      content: 'some public key data'
    )
  end

  it 'fills in the private key file' do
    expect(chef_run).to create_file('/home/jenkins/.ssh/id_rsa').with(
      owner: 'jenkins',
      group: 'jenkins',
      mode: 0600,
      content: 'some private key data'
    )
  end

  it 'fills in the known hosts file' do
    expect(chef_run).to create_file('/etc/ssh/ssh_known_hosts').with(
      owner: 'root',
      group: 'root',
      mode: 0644,
      # ssh-keygen expects a trailing newline or else it errors
      content: "cvs.example.com ssh-rsa AAA\ngit.example.com ssh-rsa BBB\n"
    )
  end

  context 'when the private_key content is nil' do
    let(:private_key_content) { nil }
    it 'does not write the private key file' do
      expect(chef_run).not_to create_file('/home/jenkins/.ssh/id_rsa')
    end
  end

  context 'when the public_key content is nil' do
    let(:public_key_content) { nil }
    it 'does not write the public key file' do
      expect(chef_run).not_to create_file('/home/jenkins/.ssh/id_rsa.pub')
    end
  end
end
