#!/usr/bin/env bats

@test "the go_and_ruby script is available" {
  which go_and_ruby
}

@test "sourcing go_and_ruby provides go 1.2" {
  source go_and_ruby
  go version | grep 1.2
}

@test "sourcing go_and_ruby provides chruby and ruby 1.9.3 is available" {
  source go_and_ruby
  chruby 1.9.3
  ruby -v | grep 1.9.3
}
