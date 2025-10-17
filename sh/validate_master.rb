#!/usr/bin/env ruby
# Master.json validation orchestrator v503.0.0
# Runs every file through master.json governance individually and collectively
# Per master.json execution.active_execution.mode: "always_on"

require 'json'
require 'fileutils'

# OpenBSD dmesg-style logging
def log(facility, level, message, emoji = "→")
  timestamp = Time.now.strftime("%b %d %H:%M:%S")
  hostname = "localhost"
  service = "master"
  pid = 503
  puts "#{timestamp} #{hostname} #{service}[#{pid}]: #{facility}.#{level}: #{emoji} #{message}"
end

# Load master.json (strip comments)
raw = File.read("G:/pub/master.json")
# Remove leading // comment lines
json_content = raw.lines.reject { |line| line.strip.start_with?("//") }.join
MASTER_JSON = JSON.parse(json_content)

# Phase definitions from master.json
PHASES = {
  discover: "Discover all files and understand structure",
  alternatives: "Generate 15 alternative approaches per principle",
  adversarial: "Run 10 adversarial personas critique",
  select: "Select best alternative with justification",
  implement: "Implement with continuous validation",
  verify: "Verify against all quality gates"
}

# Quality gates from master.json
QUALITY_GATES = MASTER_JSON.dig("execution", "quality_gates") || {}

# Modern zsh patterns from master.json
ZSH_PATTERNS = MASTER_JSON.dig("shell_builtins") || {}

# Design principles from master.json
DESIGN_PRINCIPLES = MASTER_JSON.dig("design", "tadao_ando") || {}

# Validation results
RESULTS = {
  individual: {},
  collective: {},
  violations: [],
  warnings: [],
  successes: []
}

# Check file against master.json principles
def validate_file(file_path)
  log("validate", "info", "Checking #{file_path}", "🔍")

  return { skipped: true, reason: "binary file" } unless file_path.end_with?(".sh", ".rb", ".md", ".html", ".css", ".erb")
  return { skipped: true, reason: "not found" } unless File.exist?(file_path)

  content = File.read(file_path)
  violations = []
  warnings = []

  # Check 1: Modern zsh patterns (for .sh files)
  if file_path.end_with?(".sh")
    ZSH_PATTERNS.dig("never_use")&.each do |forbidden|
      if content =~ /\b#{Regexp.escape(forbidden)}\b/
        violations << "Uses forbidden command: #{forbidden} (use pure parameter expansion)"
      end
    end

    # Check for external forks
    if content =~ /\$\((?!cat|echo)/
      warnings << "Uses command substitution - consider pure parameter expansion"
    end
  end

  # Check 2: Security (for all files)
  if content =~ /password.*=.*["'][^"']{1,20}["']/i
    violations << "Hardcoded credential detected"
  end

  if content =~ /api[_-]?key.*=.*["'][^"']+["']/i
    violations << "Hardcoded API key detected"
  end

  # Check 3: Design principles (for HTML/ERB files)
  if file_path.end_with?(".html", ".erb")
    if content !~ /max-width:\s*680px/ && content.length > 500
      warnings << "Missing 680px max width constraint (Tadao Ando principle)"
    end

    if content !~ /font-family.*system-ui/i && content.length > 500
      warnings << "Not using system fonts (performance principle)"
    end
  end

  # Check 4: Rails 8 patterns (for .sh files creating Rails apps)
  if file_path.end_with?(".sh") && content =~ /rails new/
    unless content =~ /--skip-redis/
      violations << "Missing --skip-redis flag (Rails 8 uses Solid Queue/Cache/Cable)"
    end

    unless content =~ /solid_queue|solid_cache|solid_cable/
      warnings << "Should explicitly configure Solid Queue/Cache/Cable"
    end
  end

  # Check 5: File structure conventions
  if file_path.end_with?(".rb")
    unless content.start_with?("#!/usr/bin/env ruby") || content =~ /^# frozen_string_literal:/
      warnings << "Missing shebang or frozen_string_literal pragma"
    end
  end

  if file_path.end_with?(".sh")
    unless content.start_with?("#!/") || content =~ /^#!.*zsh/
      warnings << "Missing shebang line"
    end
  end

  # Check 6: Documentation
  if file_path.end_with?(".sh", ".rb") && content.length > 1000
    unless content =~ /^# .{20,}/
      warnings << "Large file without substantial header comments"
    end
  end

  {
    violations: violations,
    warnings: warnings,
    lines: content.lines.count,
    size: content.bytesize
  }
end

# Discover files in directory
def discover_files(dir)
  log("discover", "info", "Scanning #{dir}", "🔍")

  return [] unless Dir.exist?(dir)

  files = Dir.glob("#{dir}/**/*").select { |f| File.file?(f) }
  log("discover", "info", "Found #{files.count} files in #{dir}", "✓")
  files
end

# Run validation on all files
def validate_all(files)
  files.each do |file|
    result = validate_file(file)
    RESULTS[:individual][file] = result

    if result[:skipped]
      log("validate", "debug", "Skipped #{file}: #{result[:reason]}", "⊘")
    elsif result[:violations].any?
      RESULTS[:violations] << { file: file, issues: result[:violations] }
      log("validate", "error", "#{result[:violations].count} violations in #{file}", "✗")
    elsif result[:warnings].any?
      RESULTS[:warnings] << { file: file, issues: result[:warnings] }
      log("validate", "warn", "#{result[:warnings].count} warnings in #{file}", "⚠️")
    else
      RESULTS[:successes] << file
      log("validate", "info", "#{file} passed", "✓")
    end
  end
end

# Collective validation: Check directory-level patterns
def validate_collective(dir, files)
  log("validate", "info", "Running collective validation for #{dir}", "🧠")

  shell_files = files.select { |f| f.end_with?(".sh") }
  ruby_files = files.select { |f| f.end_with?(".rb") }

  issues = []

  # Check for @common.sh usage in rails directory
  if dir.include?("rails") && shell_files.any?
    common_sh = files.find { |f| f.include?("@common.sh") }

    shell_files.each do |sh_file|
      content = File.read(sh_file)
      if content !~ /source.*@common\.sh/ && content.length > 500
        issues << "#{sh_file} doesn't source @common.sh (consolidation principle)"
      end
    end
  end

  # Check for README files
  if files.none? { |f| f.end_with?("README.md") } && files.count > 5
    issues << "#{dir} lacks README.md (documentation principle)"
  end

  # Check for redundant files
  base_names = files.map { |f| File.basename(f, ".*") }
  duplicates = base_names.select { |e| base_names.count(e) > 1 }
  if duplicates.any?
    issues << "Duplicate base names detected: #{duplicates.uniq.join(", ")}"
  end

  RESULTS[:collective][dir] = {
    total_files: files.count,
    shell_files: shell_files.count,
    ruby_files: ruby_files.count,
    issues: issues
  }

  issues.each do |issue|
    log("validate", "warn", issue, "⚠️")
  end

  log("validate", "info", "Collective validation complete for #{dir}", "✓")
end

# Generate report
def generate_report
  log("report", "info", "Generating validation report", "📊")

  report = []
  report << "=" * 80
  report << "MASTER.JSON v503.0.0 VALIDATION REPORT"
  report << "Generated: #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}"
  report << "=" * 80
  report << ""

  # Individual file results
  report << "INDIVIDUAL FILE VALIDATION:"
  report << "-" * 80

  total = RESULTS[:individual].count
  skipped = RESULTS[:individual].values.count { |v| v[:skipped] }
  validated = total - skipped

  report << "Total files: #{total}"
  report << "Validated: #{validated}"
  report << "Skipped: #{skipped}"
  report << "Passed: #{RESULTS[:successes].count}"
  report << "Warnings: #{RESULTS[:warnings].count}"
  report << "Violations: #{RESULTS[:violations].count}"
  report << ""

  # Violations
  if RESULTS[:violations].any?
    report << "VIOLATIONS (MUST FIX):"
    report << "-" * 80
    RESULTS[:violations].each do |v|
      report << "File: #{v[:file]}"
      v[:issues].each { |issue| report << "  ✗ #{issue}" }
      report << ""
    end
  end

  # Warnings
  if RESULTS[:warnings].any?
    report << "WARNINGS (SHOULD FIX):"
    report << "-" * 80
    RESULTS[:warnings].each do |w|
      report << "File: #{w[:file]}"
      w[:issues].each { |issue| report << "  ⚠️  #{issue}" }
      report << ""
    end
  end

  # Collective results
  report << "COLLECTIVE VALIDATION:"
  report << "-" * 80
  RESULTS[:collective].each do |dir, data|
    report << "Directory: #{dir}"
    report << "  Total files: #{data[:total_files]}"
    report << "  Shell files: #{data[:shell_files]}"
    report << "  Ruby files: #{data[:ruby_files]}"
    if data[:issues].any?
      report << "  Issues:"
      data[:issues].each { |issue| report << "    ⚠️  #{issue}" }
    else
      report << "  ✓ No issues"
    end
    report << ""
  end

  # Quality gates summary
  report << "QUALITY GATES:"
  report << "-" * 80
  QUALITY_GATES.each do |gate, criteria|
    report << "#{gate}:"
    if criteria.is_a?(Hash)
      criteria.each { |k, v| report << "  #{k}: #{v}" }
    else
      report << "  #{criteria}"
    end
  end
  report << ""

  # Final status
  report << "=" * 80
  if RESULTS[:violations].empty?
    report << "✓ ALL FILES PASSED VALIDATION"
  else
    report << "✗ #{RESULTS[:violations].count} FILES HAVE VIOLATIONS"
  end
  report << "=" * 80

  report.join("\n")
end

# Main execution
def main
  log("master", "info", "Starting master.json validation v503.0.0", "🚀")
  log("master", "info", "Mode: always_on, continuous validation", "⚙️")

  # Phase 1: Discover
  log("phase", "info", "PHASE 1: #{PHASES[:discover]}", "🏗️")
  openbsd_files = discover_files("G:/pub/openbsd")
  rails_files = discover_files("G:/pub/rails")

  # Phase 2: Individual validation
  log("phase", "info", "PHASE 2: Individual file validation", "🔍")
  validate_all(openbsd_files)
  validate_all(rails_files)

  # Phase 3: Collective validation
  log("phase", "info", "PHASE 3: Collective validation", "🧠")
  validate_collective("G:/pub/openbsd", openbsd_files)
  validate_collective("G:/pub/rails", rails_files)

  # Phase 4: Generate report
  log("phase", "info", "PHASE 4: Generate report", "📊")
  report = generate_report

  # Write report
  report_file = "G:/pub/VALIDATION_REPORT.txt"
  File.write(report_file, report)
  log("report", "info", "Report saved to #{report_file}", "✓")

  # Display report
  puts ""
  puts report

  # Exit code
  exit_code = RESULTS[:violations].empty? ? 0 : 1
  log("master", "info", "Validation complete, exit code: #{exit_code}", exit_code == 0 ? "✓" : "✗")
  exit(exit_code)
end

# Run
main
