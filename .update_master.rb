#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"

master_path = "G:/pub/master.json"
content = File.read(master_path)
data = JSON.parse(content)

data["claude_code"] = {
  "mode" => "ultra_low_token_efficiency",
  "strategy" => "parallel_exploration_deep_search",
  "use_agents" => true,
  "prefer_tools" => ["Task", "Explore", "Read", "Grep", "Glob"],
  "verbose" => true,
  "rationale" => "maximize_thoroughness_over_speed"
}

data["voice"] = {
  "enabled" => true,
  "lang" => "ms",
  "tld" => "com.my",
  "slow" => false,
  "engine" => "gtts",
  "script" => "G:/pub/tts/say.rb",
  "auto_speak" => false
}

data["workflow"] = {
  "pre_commit" => ["G:/pub/sh/clean.sh", "G:/pub/sh/lint.sh"],
  "pre_push" => ["test", "coverage"],
  "continuous" => ["monitor_dimensions", "auto_optimize"]
}

data["paths"] = {
  "root" => "G:/pub",
  "multimedia" => "G:/pub/multimedia",
  "dilla" => "G:/pub/multimedia/dilla",
  "rails" => "G:/pub/rails",
  "scripts" => "G:/pub/sh",
  "tts" => "G:/pub/tts",
  "openbsd" => "G:/pub/openbsd",
  "repligen" => "G:/pub/multimedia/repligen"
}

File.write(master_path, JSON.pretty_generate(data))
puts "✓ Updated master.json successfully"
