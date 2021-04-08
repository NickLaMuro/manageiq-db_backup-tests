require "test_helper"

require_relative "./support/mount_helper.rb"

class NFSBackupTest < BaseBackupTest
  include MountHelper

  def test_nfs_database_backup
    console_nfs_backup_file = "console_full_nfs_backup.tar.gz"

    run_in_mount :nfs do |mount_point|
      mount_file = File.join(mount_point, "db_backup", console_nfs_backup_file)
      ApplianceConsoleRunner.backup mount_file, :nfs
    end

    run_in_mount :nfs do |mount_point|
      mount_file = File.join(mount_point, "db_backup", console_nfs_backup_file)

      assert_file_exists mount_file
      assert_valid_database mount_file
    end
  end

  def test_nfs_database_dump
    console_nfs_dump_file = "console_full_nfs_dump.tar.gz"

    run_in_mount :nfs do |mount_point|
      mount_file = File.join(mount_point, "db_dump", console_nfs_dump_file)
      ApplianceConsoleRunner.dump mount_file, :nfs
    end

    run_in_mount :nfs do |mount_point|
      mount_file = File.join(mount_point, "db_dump", console_nfs_dump_file)

      assert_file_exists mount_file
      assert_valid_database mount_file
    end
  end

  def test_nfs_database_dump_excluding_custom_attributes
    console_nfs_dump_file_without_ca = "console_partial_nfs_dump_without_custom_attributes.tar.gz"

    run_in_mount :nfs do |mount_point|
      mount_file = File.join(mount_point, "db_dump", console_nfs_dump_file_without_ca)
      ApplianceConsoleRunner.dump_with_no_custom_attributes mount_file, :nfs
    end

    run_in_mount :nfs do |mount_point|
      mount_file = File.join(mount_point, "db_dump", console_nfs_dump_file_without_ca)

      assert_file_exists mount_file
      refute_has_custom_attributes mount_file
    end
  end

  def teardown
    ApplianceConsoleRunner::Current.instance = nil
  end
end
