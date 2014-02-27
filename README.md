# cf_pipeline

[![Build Status](https://travis-ci.org/pivotal-cf-experimental/cf_pipeline.png?branch=master)](https://travis-ci.org/pivotal-cf-experimental/cf_pipeline)

A set of cookbooks to build CloudFoundry deployment pipelines.

Work in progress.

## What does the cookbook offer?

After running the default `cf_pipeline` recipe with valid attributes, you will have a machine with:

* Jenkins running behind nginx
* A user named `jenkins`
* Go 1.2 (version configurable through overrides, see )
* Ruby 1.9.3-p484 (version configurable through overrides, see [attributes/ruby_versions.rb](attributes/ruby_versions.rb))

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

## Development

### Tips for running tests successfully

When you run test-kitchen, it creates a `.librarian/chef/config` file that sets your librarian cookbook directory to a temporary directory.
However, RSpec expects your cookbooks to exist in the `cookbooks` directory.

You should be able to run `kitchen converge && kitchen verify` at any time, but after that, you should run `rm -rf .librarian/ && librarian-chef install` to get your unit tests to use the cookbook as it currently resides on disk.

### My tests are really slow!

This is almost certainly because of large files in the packer/ folder that are being copied over when `librarian-chef install` is automatically run before your specs.
If you remove the large files from the packer/ folder, then `librarian-chef install` will run much more quickly.
