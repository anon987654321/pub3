#!/usr/bin/env ruby
# Consolidate all root JSON files and run auto-convergence

require 'json'
require 'time'

# Deep merge hashes, preferring newer values
def deep_merge(base, overlay)
  base.merge(overlay) do |key, old_val, new_val|
    if old_val.is_a?(Hash) && new_val.is_a?(Hash)
      deep_merge(old_val, new_val)
    elsif old_val.is_a?(Array) && new_val.is_a?(Array)
      (old_val + new_val).uniq
    else
      new_val
    end
  end
end

# Load JSON, handling JSON5 comments
def load_json(path)
  content = File.read(path)
  # Remove // comments
  content = content.gsub(%r{^\s*//.*$}, '')
  # Remove /* */ comments
  content = content.gsub(%r{/\*.*?\*/}m, '')
  JSON.parse(content)
rescue JSON::ParserError => e
  puts "ERROR parsing #{path}: #{e.message}"
  {}
end

# Detect DRY violations
def detect_dry_violations(data, path = [])
  violations = []
  return violations unless data.is_a?(Hash)

  # Check for repeated string values (>3 occurrences)
  value_counts = {}
  data.each do |k, v|
    if v.is_a?(String) && v.length > 10
      value_counts[v] ||= []
      value_counts[v] << (path + [k]).join('.')
    elsif v.is_a?(Hash) || v.is_a?(Array)
      violations += detect_dry_violations(v, path + [k])
    end
  end

  value_counts.each do |val, paths|
    if paths.size >= 3
      violations << {
        type: 'dry_literal',
        value: val[0,50],
        count: paths.size,
        paths: paths,
        severity: 4
      }
    end
  end

  violations
end

# Detect nesting violations (depth > 3)
def detect_nesting_violations(data, path = [], depth = 0)
  violations = []
  return violations unless data.is_a?(Hash)

  if depth > 3
    violations << {
      type: 'nesting_excessive',
      path: path.join('.'),
      depth: depth,
      severity: 3
    }
  end

  data.each do |k, v|
    violations += detect_nesting_violations(v, path + [k], depth + 1) if v.is_a?(Hash)
  end

  violations
end

# Main consolidation
puts "=== Consolidating JSON files ==="

# Load all files in priority order (v6 first for CRITICAL sections)
files = {
  v6: 'master.json5',
  v42: 'v42.json',
  v20: 'v20.json',
  v7: 'master.json',
  v16: 'v16.json'
}

loaded = {}
files.each do |version, path|
  next unless File.exist?(path)
  puts "Loading #{path}..."
  loaded[version] = load_json(path)
  puts "  Keys: #{loaded[version].keys.join(', ')}"
end

# Deep merge in order (v6 base, then overlay others)
consolidated = loaded[:v6] || {}
[:v42, :v20, :v7, :v16].each do |version|
  next unless loaded[version]
  puts "\nMerging #{version}..."
  consolidated = deep_merge(consolidated, loaded[version])
end

# Update meta
consolidated['meta'] ||= {}
consolidated['meta']['version'] = '8.0.0-consolidated'
consolidated['meta']['updated'] = Time.now.utc.iso8601
consolidated['meta']['consolidated_from'] = files.keys.map(&:to_s)
consolidated['meta']['auto_converged'] = false

puts "\n=== Running Auto-Convergence ==="

MAX_ITERATIONS = 10
iteration = 1

loop do
  puts "\nIteration #{iteration}:"

  # Detect violations
  dry_violations = detect_dry_violations(consolidated)
  nesting_violations = detect_nesting_violations(consolidated)

  total_violations = dry_violations.size + nesting_violations.size

  puts "  DRY violations: #{dry_violations.size}"
  puts "  Nesting violations: #{nesting_violations.size}"
  puts "  Total: #{total_violations}"

  # Convergence achieved
  if total_violations == 0
    puts "\n✓ CONVERGED at iteration #{iteration} - Zero violations!"
    consolidated['meta']['auto_converged'] = true
    consolidated['meta']['convergence_iterations'] = iteration
    break
  end

  # Max iterations reached
  if iteration >= MAX_ITERATIONS
    puts "\n⚠ Max iterations reached. #{total_violations} violations remain."
    consolidated['meta']['convergence_iterations'] = iteration
    break
  end

  # Show top violations
  if dry_violations.any?
    puts "\n  Top DRY violations:"
    dry_violations.first(3).each do |v|
      puts "    - \"#{v[:value]}...\" repeated #{v[:count]}x"
    end
  end

  if nesting_violations.any?
    puts "\n  Top nesting violations:"
    nesting_violations.first(3).each do |v|
      puts "    - #{v[:path]} (depth #{v[:depth]})"
    end
  end

  iteration += 1
end

# Write final consolidated file
output_path = 'master.json'
puts "\n=== Writing #{output_path} ==="
File.write(output_path, JSON.pretty_generate(consolidated))
puts "✓ Written #{File.size(output_path)} bytes"

# Summary
puts "\n=== Consolidation Summary ==="
puts "Input files: #{loaded.size}"
puts "Output: #{output_path}"
puts "Top-level keys: #{consolidated.keys.size}"
puts "Converged: #{consolidated['meta']['auto_converged']}"
puts "Iterations: #{consolidated['meta']['convergence_iterations']}"
