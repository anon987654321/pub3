#!/usr/bin/env ruby
# aight.rb - Interactive Ruby REPL with LLM integration and Starship prompt
# Follows master.json v502.0.0 principles

require_relative "lib/repl"
require_relative "lib/starship_module"
require "optparse"

# OpenBSD security (pledge/unveil)
if RUBY_PLATFORM.include?("openbsd")
  begin
    require "pledge"
    Pledge.promises(:stdio, :rpath, :wpath, :cpath, :proc, :exec, :inet, :dns, :tty)
    require "unveil"
    Unveil.call("/tmp", "rwc")
    Unveil.call("/usr/local/bin", "rx")
    Unveil.call("/usr/bin", "rx")
    Unveil.call(Dir.home, "rwc")
    Unveil.call(__dir__, "r")
  rescue LoadError
    # pledge/unveil gems not available
  end
end

# Parse command line arguments
options = {
  mode: :repl,
  verbose: false,
  model: ENV["AIGHT_MODEL"] || "gpt-4",
  starship: false
}

OptionParser.new do |opts|
  opts.banner = "Usage: aight [options]"

  opts.on("-r", "--repl", "Start interactive REPL (default)") do
    options[:mode] = :repl
  end

  opts.on("-s", "--starship", "Generate Starship configuration") do
    options[:mode] = :starship
  end

  opts.on("-c", "--completions", "Install zsh completions") do
    options[:mode] = :completions
  end

  opts.on("-m", "--model MODEL", "Set LLM model (default: gpt-4)") do |model|
    options[:model] = model
  end

  opts.on("-v", "--verbose", "Enable verbose output") do
    options[:verbose] = true
  end

  opts.on("-h", "--help", "Show this help message") do
    puts opts
    exit
  end
end.parse!

# Execute selected mode
case options[:mode]
when :repl
  Aight::REPL.new(options).start
when :starship
  Aight::StarshipModule.generate_config
when :completions
  Aight::StarshipModule.install_completions
end
