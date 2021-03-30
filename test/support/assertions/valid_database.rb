require_relative '../db_filename_helper.rb'

class DbTestCase
  include DbFilenameHelper

  attr_reader :backups_to_validate

  def self.validate *dbs
    new(*dbs).validate
  end

  # Similar to the above, but doesn't run inside of a `testing` block
  def self.valid_database? *dbs
    new(*dbs).valid_databases?
  end

  def self.no_custom_attributes? *dbs
    new(*dbs).no_custom_attributes?
  end

  def initialize *dbs
    @backups_to_validate = dbs
  end

  def validate
    testing validation_message do
      valid_databases?
    end
  end

  def valid_databases?
    backups_to_validate.each { |db| assert_valid_database db }
  end

  def no_custom_attributes?
    backups_to_validate.each { |db| assert_no_custom_attributes db }
  end

  private

  def validation_message
    message = nil
    backups_to_validate.each do |filename|
      location, type, _ = parse_db_filename filename

      new_message = "#{location} #{type}s are valid"
      if message && message != new_message
        raise ArgumentError, "use one backup type/location at a time"
      end
      message ||= new_message
    end
    message
  end

  def assert_no_custom_attributes backup_file
    DbValidator.no_custom_attributes?(backup_file) || fail("custom_attributes is present in #{backup_file}")
  end

  def assert_valid_database backup_file
    DbValidator.validate(backup_file) || raise("invalid DB (call 'fail' below)")
  rescue => e
    fail <<-ERR.gsub(/^ {4}/, '') + e.backtrace.map { |l| "    #{l}" }.join("\n")
      #{backup_file} was not a valid database

        Error:  #{e.message}
    ERR
  end
end

module Assertions
  module ValidDatabase
    def assert_valid_database(backup_file)
      assert DbValidator.validate(backup_file), "#{backup_file} was not a valid database"
    end
  end
end
