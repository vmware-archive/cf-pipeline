# cf_pipeline

[![Build Status](https://travis-ci.org/pivotal-cf-experimental/cf_pipeline.png?branch=master)](https://travis-ci.org/pivotal-cf-experimental/cf_pipeline)

A set of cookbooks to build CloudFoundry deployment pipelines.

Work in progress.

## What does the cookbook offer?

After running the default `cf_pipeline` recipe with valid attributes, you will have a machine with:

* Jenkins running behind nginx
* A user named `jenkins`
* Go 1.2 (version not currently configurable)
* Ruby 1.9.3-p484 (version configurable through Chef overrides)

## How do I configure this cookbook?

There are two main flows when using the cookbook:

1. Pipelines
  * Follow a predetermined flow of creating/uploading/deploying a Bosh release
  * Execute `script/run_system_tests` (which must be checked in to your Git repository) to validate that the Bosh release works correctly
  * Create a release tarball and save it as a Jenkins artifact
2. One-off jobs
  * Execute a specified script in your Git repository, optionally triggering another job (another script in your repo)

### Bare minimum config

Like most Chef cookbooks, `cf_pipeline` is configured through attributes.
A bare minimum config that installs Jenkins but does not configure any jobs looks like this:

```yaml
cf_pipeline:
  pipelines: {}
  jobs: {}
  ssh:
    public_key: content_of_public_key_for_jenkins_to_use
    private_key: content_of_private_key_for_jenkins_to_use
  github_oauth:
    enable: false # leaves Jenkins unsecured - not recommended for machines on publicly accessible networks
```

Further configuration examples will include the top-level `cf_pipeline` key but will exclude some of the above-mentioned keys for brevity.

### One-off jobs that trigger other jobs

If you had a repository with a `unit_test.sh` script and an `integration_tests.sh` script, and you wanted Jenkins to run one job for unit tests that triggered the job for integrations tests, then your `jobs` attribute might look like this:

```yaml
cf_pipeline:
  jobs:
    my_unit_tests: # create a Jenkins job named "my_unit_tests"
      git: https://github.com/my-org/my-repo # url to the repository
      git_ref: master # sha, branch name, etc.
      script_path: tests/unit_tests.sh
      env: # the script is always called without arguments, so use env to set environment variables that the script can consume
        LOG_LEVEL: debug # for example
      trigger_on_success:
        - my_integration_tests # trigger the Jenkins job with this name

    my_integration_tests:
      git: https://github.com/my-org/my-repo # url to the repository
      git_ref: master # sha, branch name, etc.
      script_path: tests/integration_tests.sh
```

### Pipelines

To set up an example pipeline that deploys a "dummy" Bosh release to Bosh Lite:

```yaml
cf_pipeline:
  pipelines:
    example:
      git: https://github.com/pivotal-cf-experimental/dummy-boshrelease.git
      release_ref: master
      infrastructure: warden
      deployments_repo: https://github.com/pivotal-cf-experimental/deployments-bosh-lite.git
      deployment_name: bosh-lite
```

With this configuration, three Jenkins jobs will be created:

1. example-deploy
  * Use `cf_deployer` to create a release, upload it, and deploy it to the Bosh director specified in the `deployments-bosh-lite/bosh-lite/bosh_environment` file
  * Triggers the next job on success
2. example-system_tests
  * Runs `dummy-boshrelease/script/run_system_tests`
  * Triggers the next job on success
3. example-release_tarball
  * Uses bosh to create a release tarball and saves that output as a Jenkins artifact

The `infrastructure` key must be one of the infrastructures that `cf_deployer` considers valid (currently `warden`, `aws`, or `vsphere`).

### Other configuration options

#### Ruby versions

```yaml
rubies:
  list:
    - ruby 1.9.3-p484
    - ruby 2.0.0-p353
  install_bundler: true
```

#### Packages

Set the `cf_pipeline.packages` attribute to specify other packages to be installed (e.g. with `apt-get` on Ubuntu):

```yaml
cf_pipeline:
  packages: # install the set of packages needed to support Capybara
    - qt4-dev-tools
    - libqt4-dev
    - libqt4-core
    - libqt4-gui
    - xvfb
```

Note that there are a number of non-optional packages installed automatically for Jenkins to run properly.

#### GitHub OAuth

To configure GitHub OAuth as a means of authentication for your Jenkins instance, you'll need to configure attributes specifying which GitHub users have what permissions and you will need to register your Jenkins instance as a GitHub application (for the OAuth callback).
The attributes will look like:

```yaml
cf_pipeline:
  github_oauth:
    organization: cloudfoundry # members of this GitHub organization will be given read access to the Jenkins instance
    admins: # list of GitHub usernames who will have admin access to the Jenkins UI
      - octocat
    client_id: abc123 # get this value when you configure a GitHub application
    client_secret: def456 # ditto
```

To configure the GitHub application:

1. Create a GitHub application token.
  1. Go to [Application Settings](https://github.com/settings/applications)
  1. Register new application
  1. For the authorization callback URL, use `http://your-jenkins.example.com/securityRealm/finishLogin`, replacing the domain with the domain of your Jenkins instance.
     If you don't have/know your domain yet, it's okay to put e.g. `http://localhost` for now and update it once you know the domain.

#### Jenkins Plugins

There is currently no entry point to configure a custom set of Jenkins plugins, although that functionality should be very straightforward to add.
See [recipes/jenkins_plugins.rb](recipes/jenkins_plugins.rb) for the default set of Jenkins plugins.

#### cf_deployer

To change the git revision/branch/tag of cf_deployer installed on the machine, specify `cf_pipeline.cf_deployer_ref`:

```yaml
cf_pipeline:
  cf_deployer_ref: v1.0.0 # a tag that doesn't actually currently exist
```

Most of the time, you'll want to stick with the default value here.

## How do I apply the cookbook's recipes to a machine?

There are two main options for applying this cookbook.
If you want to play with the Jenkins box locally using Virtualbox or if you want to deploy to AWS, Vagrant is probably the simplest choice.
If Vagrant doesn't have a working plugin for your infrastructure (i.e. vSphere), [soloist](https://github.com/mkocher/soloist) is a great way to go from a box with Ruby to a box that is your CI.

### Vagrant

Just set up your Vagrantfile with a chef-solo provisioner similar to this code:

```ruby
local.vm.box_url = 'https://s3.amazonaws.com/cf-pipeline-downloads/packer_virtualbox-iso_virtualbox.box'

vm_config.vm.provision(:chef_solo) do |chef|
  chef.log_level = :debug
  chef.cookbooks_path = [File.join(File.dirname(__FILE__), 'cookbooks')] # Assumes librarian-chef
  chef.add_recipe 'cf-jenkins::profile' # Debugging only, you may not want profiling
  chef.add_recipe 'cf_pipeline'
  chef.json = {
    cf_pipeline: {
      pipelines: {
        YAML.load_file(File.expand_path('pipelines.yml', __FILE__))
      },
      jobs: {
        # ...
      },
      ssh: {
        public_key: File.read(File.expand_path('~/.ssh/id_ci.pub')),
        private_key: File.read(File.expand_path('~/.ssh/id_ci')),
      },
      # etc.
    }
  }
```

Fortunately, a Vagrantfile is just Ruby code, so that lets us be a little more clever about dynamic or confidential information in the configuration.

### Soloist

There are more manual steps involved in a soloist configuration.
You'll need a soloistrc file, which will look something like this YAML:

```yaml
recipes:
  - cf_pipeline
node_attributes:
  cf_pipeline:
    # ...
```

The soloistrc is just a static YAML file, so if you have a need for dynamic information in your attributes, you may want to write a script to generate the soloistrc.

You will also need a Cheffile that looks awfully similar to the one in this repository, minding that the declaration for the cf_pipeline cookbook will need to change to a git reference.

Finally, run `gem install soloist && soloist` to apply the recipes on that box.
If you don't have Ruby available on the box yet, it is fine to install Ruby with whatever mechanism that system provides (e.g. `apt-get install ruby19` on Ubuntu).
The recipes will install another, isolated Ruby to be used by Jenkins.

## Development

### Tips for running tests successfully

When you run test-kitchen, it creates a `.librarian/chef/config` file that sets your librarian cookbook directory to a temporary directory.
However, RSpec expects your cookbooks to exist in the `cookbooks` directory.

You should be able to run `kitchen converge && kitchen verify` at any time, but after that, you should run `rm -rf .librarian/ && librarian-chef install` to get your unit tests to use the cookbook as it currently resides on disk.

### My tests are really slow!

This is almost certainly because of large files in the packer/ folder that are being copied over when `librarian-chef install` is automatically run before your specs.
If you remove the large files from the packer/ folder, then `librarian-chef install` will run much more quickly.

## Troubleshooting

### 500 error when waiting for Jenkins to start

The Chef log will normally show a series of 503 responses while waiting for Jenkins to start.
If it begins showing 500 responses after that, the Chef run will fail.
In that case, you can log onto the machine and run `sudo service jenkins restart`, or you can restart the whole machine.
