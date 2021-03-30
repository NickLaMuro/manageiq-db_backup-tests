require 'tmpdir'
require 'singleton'

# require_relative "./smoketest_env_helper.rb"
require_relative "./support/db_validator.rb"
require_relative "./support/db_connection.rb"

require_relative "./support/appliance_console_runner.rb"

require_relative "./support/mount_helper.rb"
require_relative "./support/vmdb_helper.rb"

require_relative "./support/assertions/custom_attributes.rb"
require_relative "./support/assertions/file_exists.rb"
require_relative "./support/assertions/valid_database.rb"

require "minitest/autorun"

class BaseBackupTest < Minitest::Test
  include VmdbHelper

  include Assertions::CustomAttributes
  include Assertions::FileExists
  include Assertions::ValidDatabase
end
