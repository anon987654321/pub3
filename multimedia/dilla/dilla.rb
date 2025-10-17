#!/usr/bin/env ruby
# Alias entrypoint for the Dilla generator.
# Usage:
#   ruby multimedia/dilla/dilla.rb [--all|--chords-only|--drums-only|--quick]
#
# This simply delegates to master.rb with the same argv.
# Works on Cygwin/OpenBSD/Windows as long as Ruby can exec.

require "rbconfig"

master = File.join(__dir__, "master.rb")
exec RbConfig.ruby, master, *ARGV
