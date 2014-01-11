# How to use Packer with cf_pipeline

## Prerequisites

From the root of the cf_pipeline repository, you must run `librarian-chef update cf_pipeline && librarian-chef install` prior to running Packer.
If you don't run that command, the packer provisioning step will likely fail with strange errors about missing recipes.

If you *did* run that command and packer *still* fails to provision, check `.librarian/chef/config` which may have been set to something ridiculous thanks to test-kitchen.
While that normally wouldn't matter, packer expects to be given an explicit cookbook path, which we have configured to be the cookbooks folder in the root of the repository.
Feel free to remove the whole `.librarian` directory and then re-run the librarian-chef commands from above.

You will also need to have packer installed and on your path.

## Usage

### Validate your Packer configuration file

```shell
cd ~/workspace/cf_pipeline/packer
packer validate packer.json
```

### Generate a Vagrant box for VirtualBox

```shell
cd ~/workspace/cf_pipeline/packer
packer build -only=virtualbox-iso packer.json
```

The Vagrant box will be at `~/workspace/cf_pipeline/packer/packer_virtualbox-iso_virtualbox.box`.

### Generate an AMI for Amazon

```shell
cd ~/workspace/cf_pipeline/packer
packer build -only=amazon-ebs -var 'aws_access_key=YOUR_ACCESS_KEY' -var 'aws_secret_key=YOUR_SECRET_KEY' packer.json
```

The output will tell you the ID of the AMI generated.
