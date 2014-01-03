#!/bin/bash

ssh_dir=/home/vagrant/.ssh
mkdir -p $ssh_dir
chmod 700 $ssh_dir
curl https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub > $ssh_dir/authorized_keys
chmod 600 $ssh_dir/authorized_keys
chown -R vagrant:vagrant $ssh_dir
