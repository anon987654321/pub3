#!/usr/bin/env ruby
# frozen_string_literal: true

# CRC - Claude Ruby CLI
# Autonomous AI coding assistant with Claude load awareness

require "yaml"
require "json"
require "fileutils"
require "pathname"
require "logger"
require "concurrent-ruby"
require "digest"
require "io/console"

LANGCHAIN_AVAILABLE = begin
  require "langchainrb"
  true
rescue LoadError
  false
end

OCTOKIT_AVAILABLE = begin
  require "octokit"
  true
rescue LoadError
  false
end

RUGGED_AVAILABLE = begin
  require "rugged"
  true
rescue LoadError
  false
end

LISTEN_AVAILABLE = begin
  require "listen"
  true
rescue LoadError
  false
end

AST_AVAILABLE = begin
  require "parser/current"
  require "rubocop/ast"
  true
rescue LoadError
  false
end

FERRUM_AVAILABLE = begin
  require "ferrum"
  true
rescue LoadError
  false
end

PLEDGE_AVAILABLE = begin
  require "pledge"
  true
rescue LoadError
  RbConfig::CONFIG["host_os"] =~ /openbsd/
end

# Load modular components
require_relative "lib/aight/config"
require_relative "lib/aight/prompts"
require_relative "lib/aight/tools"
require_relative "lib/aight/assistant"
require_relative "lib/aight/cli"

# Main execution
if __FILE__ == $0
  check_dependencies
  
  begin
    cli = CognitiveRubyCLI.new
    cli.run
  rescue Interrupt
    puts "\nExiting..."
    exit(0)
  rescue => e
    puts "Fatal error: #{e.message}"
    puts "Check configuration and dependencies"
    exit(1)
  end
end
