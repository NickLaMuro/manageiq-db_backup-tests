require 'singleton'

class TestConfig
  include Singleton

  CONFIG_METHODS = %w[
    clean skip_backups skip_dumps
    skip_splits skip_restore
    include_s3 include_swift
    restore_from_original_dir
  ]

  CONFIG_METHODS.each do |config|
    attr_accessor config

    define_singleton_method config do
      instance.public_send config
    end

    define_singleton_method "#{config}=" do |val|
      instance.public_send "#{config}=", val
    end
  end

  def self.clean?
    clean
  end

  def self.run_test? test
    run_backup?(test) && run_dump?(test) && run_split?(test) && run_s3?(test) && run_swift?(test)
  end

  def self.run_backup? test
    !(TestConfig.skip_backups && test =~ /(evm:db:backup|Database Backup)/)
  end

  def self.run_dump? test
    !(TestConfig.skip_dumps && test =~ /(evm:db:dump|Database Dump)/)
  end

  def self.run_split? test
    !(TestConfig.skip_splits  && test =~ /(-b 2M|:  Split)/)
  end

  def self.run_s3? test
    (TestConfig.include_s3 || !(test =~ /(_s3_|S3 Database)/))
  end

  def self.run_swift? test
    (TestConfig.include_swift || !(test =~ /(_swift_|Swift Database)/))
  end
end

# Defaults
TestConfig.clean                      = false
TestConfig.include_s3                 = true
TestConfig.include_swift              = true
TestConfig.skip_backups               = false
TestConfig.skip_dumps                 = false
TestConfig.skip_splits                = false
TestConfig.skip_restore               = true
TestConfig.restore_from_original_dir  = false
