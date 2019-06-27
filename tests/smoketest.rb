require 'optparse'
require_relative "./smoketest_config.rb"

OptionParser.new do |opts|
  opts.banner = "Usage: smoketest.rb [options]"

  opts.on("--clean",        "Clean old artifacts from tests before run (def: false)") do |clean|
    TestConfig.clean = clean
  end

  opts.on("--[no-]s3",      "Run/Skip s3 functionality (def: run)") do |use_s3|
    TestConfig.include_s3 = use_s3
  end

  opts.on("--[no-]swift",   "Run/Skip swift functionality (def: run)") do |use_swift|
    TestConfig.include_swift = use_swift
  end

  opts.on("--[no-]backups", "Run/Skip backup functionality (def: run)") do |skip|
    TestConfig.skip_backups = !skip
  end

  opts.on("--[no-]dumps",   "Run/Skip dump functionality (def: run)") do |skip|
    TestConfig.skip_dumps = !skip
  end

  opts.on("--[no-]splits",  "Run/Skip split functionality (def: run)") do |skip|
    TestConfig.skip_splits = !skip
  end

  opts.on("--[no-]restore", "Run/Skip testing restores (def: skip)") do |skip|
    TestConfig.skip_restore = !skip
  end

  opts.on("--restore-from-orig", "Run restores from their downloaded dir (def: false)") do
    TestConfig.restore_from_original_dir = true
  end

  opts.on("-h", "--help") { puts opts.help; exit 1 }
end.parse!

require_relative "./smoketest_test_helper.rb"

clean

require_relative "./smoketest_db_tasks.rb"
require_relative "./smoketest_appliance_console.rb"
