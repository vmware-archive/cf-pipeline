apt-get install -y linux-headers-$(uname -r) build-essential make perl
apt-get install -y dkms

mount -o loop /home/vagrant/VBoxGuestAdditions.iso /mnt
sh /mnt/VBoxLinuxAdditions.run
umount /mnt
rm /home/vagrant/VBoxGuestAdditions.iso
