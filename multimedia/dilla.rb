#!/usr/bin/env ruby
# Dilla Audio Generator - Top-level Entrypoint
#
# Purpose: Stable entrypoint that delegates to multimedia/dilla/master.rb
# Usage: ruby multimedia/dilla.rb [options]
#
# This wrapper allows a consistent interface regardless of internal reorganization.

# Load the actual implementation
master_path = File.join(__dir__, "dilla", "master.rb")

unless File.exist?(master_path)
  puts "Error: Cannot find multimedia/dilla/master.rb"
  exit 1
end

# Execute with same ARGV
load master_path
