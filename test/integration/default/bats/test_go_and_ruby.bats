#!/usr/bin/env bats

@test "the go_and_ruby script is available" {
  which go_and_ruby
}

@test "sourcing go_and_ruby provides go 1.2" {
  source `which go_and_ruby`
  go version | grep 1.2
}

@test "sourcing go_and_ruby provides ruby 1.9.3" {
  source `which go_and_ruby`
  ruby -v | grep 1.9.3
}
