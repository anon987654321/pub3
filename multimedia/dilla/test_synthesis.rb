#!/usr/bin/env ruby
# Test script for audio synthesis capabilities
# Verifies that the new features work correctly

require_relative 'audio_synthesis'

puts "Audio Synthesis Test Suite"
puts "=" * 70

test_count = 0
passed = 0

# Test 1: Module loads correctly
test_count += 1
begin
  AudioSynthesis.sox_path = "sox"
  puts "✓ Test 1: Module loads successfully"
  passed += 1
rescue => e
  puts "✗ Test 1: Module loading failed - #{e.message}"
end

# Test 2: Per-note swing timing calculation
test_count += 1
begin
  notes = [
    {freq: 261.63, duration: 2.0, offset: 0},
    {freq: 329.63, duration: 2.0, offset: 0},
    {freq: 392.00, duration: 2.0, offset: 0},
    {freq: 493.88, duration: 2.0, offset: 0}
  ]
  
  swung_notes = AudioSynthesis.apply_per_note_swing(notes, swing_amount: 0.58)
  
  # Verify that odd notes have swing offset
  if swung_notes[1][:offset] > 0 && swung_notes[3][:offset] > 0
    puts "✓ Test 2: Per-note swing timing works correctly"
    puts "  - Note 1 offset: #{swung_notes[1][:offset].round(4)}s"
    puts "  - Note 3 offset: #{swung_notes[3][:offset].round(4)}s"
    passed += 1
  else
    puts "✗ Test 2: Swing offsets not applied correctly"
  end
rescue => e
  puts "✗ Test 2: Per-note swing failed - #{e.message}"
end

# Test 3: Microtonality application
test_count += 1
begin
  notes = [{freq: 440.0, duration: 1.0, offset: 0}]
  microtuned = AudioSynthesis.apply_per_note_swing(notes, microtonal_cents: 10)
  
  # Verify frequency was adjusted
  if microtuned[0][:freq] != 440.0
    puts "✓ Test 3: Microtonality applied (#{microtuned[0][:freq].round(2)} Hz)"
    passed += 1
  else
    puts "✗ Test 3: Microtonality not applied"
  end
rescue => e
  puts "✗ Test 3: Microtonality failed - #{e.message}"
end

# Test 4: Cleanup utility
test_count += 1
begin
  # Create a temporary file
  File.write("_test_cleanup.tmp", "test")
  AudioSynthesis.cleanup("_test_cleanup.tmp")
  
  if !File.exist?("_test_cleanup.tmp")
    puts "✓ Test 4: Cleanup utility works"
    passed += 1
  else
    puts "✗ Test 4: Cleanup didn't remove file"
    File.delete("_test_cleanup.tmp") if File.exist?("_test_cleanup.tmp")
  end
rescue => e
  puts "✗ Test 4: Cleanup failed - #{e.message}"
  File.delete("_test_cleanup.tmp") if File.exist?("_test_cleanup.tmp")
end

# Test 5: Golden ratio swing (J Dilla's signature)
test_count += 1
begin
  notes = [
    {freq: 261.63, duration: 2.0, offset: 0},
    {freq: 329.63, duration: 2.0, offset: 0}
  ]
  
  # Apply golden ratio swing (0.542 = 54.2%)
  swung = AudioSynthesis.apply_per_note_swing(notes, swing_amount: 0.542)
  
  # Golden ratio swing should create ~4.2% offset
  expected_offset = 2.0 * (0.542 - 0.5) * 0.5
  actual_offset = swung[1][:offset]
  
  if (actual_offset - expected_offset).abs < 0.001
    puts "✓ Test 5: Golden ratio swing calculation correct"
    puts "  - Expected: #{expected_offset.round(4)}s, Got: #{actual_offset.round(4)}s"
    passed += 1
  else
    puts "✗ Test 5: Golden ratio swing offset incorrect"
    puts "  - Expected: #{expected_offset.round(4)}s, Got: #{actual_offset.round(4)}s"
  end
rescue => e
  puts "✗ Test 5: Golden ratio swing failed - #{e.message}"
end

puts "\n" + ("=" * 70)
puts "Test Results: #{passed}/#{test_count} passed"

if passed == test_count
  puts "✓ All tests passed!"
  exit 0
else
  puts "✗ Some tests failed"
  exit 1
end
