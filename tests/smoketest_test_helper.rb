require 'tmpdir'
require 'singleton'

require_relative "./smoketest_constants.rb"
require_relative "./smoketest_env_helper.rb"
require_relative "./smoketest_validator.rb"

require_relative "./smoketest_s3_helper.rb"
require_relative "./smoketest_ftp_helper.rb"
require_relative "./smoketest_swift_helper.rb"

require_relative "./smoketest_rake_helper.rb"
require_relative "./smoketest_appliance_console_helper.rb"

class TestErrors
  include Singleton

  def self.add description, error
    instance.add_error description, error
  end

  def self.print
    instance.print_errors
  end

  def initialize
    @errors = []
  end

  def add_error description, error
    @errors << [description, error]
  end

  def print_errors
    return if @errors.empty?

    puts ""
    puts "\e[31mThere were some failures...\e[0m"
    puts ""

    @errors.each_with_index do |(desc, error), i|
      error_message = error.message.lines.first +
                      error.message.lines[1..-1].map { |l| " " * 8 + l }.join("")

      puts <<-ERROR.gsub(/^ {4}/, '').prepend("\e[31m").concat("\e[0m")
        #{i+1}.  #{desc}

          #{error_message}

      ERROR
    end
  end
end

extend TestHelper
extend MountHelper
extend Assertions

at_exit { TestErrors.print }

def clean
  clean! if TestConfig.clean?
end

def clean!
  require 'fileutils'
  run_in_vmdb do
    File.unlink *Dir["*.tar.gz*"]
    FileUtils.rm_rf "tmp/subdir"
  end
  %i[nfs smb].each do |type|
    run_in_mount type do |mnt_dir|
      FileUtils.rm_rf File.join(mnt_dir, "db_backup")
      FileUtils.rm_rf File.join(mnt_dir, "db_dump")
      # Quicker to just do a `rm -rf` from the mount most likely
      uploads_dir = [mnt_dir, "ftp", "pub", "uploads"]
      FileUtils.rm_rf File.join(*(uploads_dir + ["db_backup"])) if type == :nfs
      FileUtils.rm_rf File.join(*(uploads_dir + ["db_dump"]))   if type == :nfs
    end
  end
  FTPHelper.clear_user_directory
  S3Helper.clear_buckets           if TestConfig.include_s3
  SwiftHelper.clear_containers     if TestConfig.include_swift
end
