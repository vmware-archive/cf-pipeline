# cf_pipeline

[![Build Status](https://travis-ci.org/pivotal-cf-experimental/cf_pipeline.png?branch=master)](https://travis-ci.org/pivotal-cf-experimental/cf_pipeline)

A set of cookbooks to build CloudFoundry deployment pipelines.

Work in progress.

## Development

### Tips for running tests successfully

When you run test-kitchen, it creates a `.librarian/chef/config` file that sets your librarian cookbook directory to a temporary directory.
However, RSpec expects your cookbooks to exist in the `cookbooks` directory.

You should be able to run `kitchen converge && kitchen verify` at any time, but after that, you should run `rm -rf .librarian/ && librarian-chef install` to get your unit tests to use the cookbook as it currently resides on disk.

### My tests are really slow!

This is almost certainly because of large files in the packer/ folder that are being copied over when `librarian-chef install` is automatically run before your specs.
If you remove the large files from the packer/ folder, then `librarian-chef install` will run much more quickly.
