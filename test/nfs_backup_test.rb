require "test_helper"

class NFSBackupTest < BaseBackupTest

  def test_nfs_database_backup
    console_nfs_backup_file = "console_full_nfs_backup.tar.gz"
    ApplianceConsoleRunner.backup console_nfs_backup_file, :nfs

    run_in_mount :nfs do |mount_point|
      mount_file = File.join(mount_point, "db_backup", console_nfs_backup_file)
      assert_file_exists mount_file
      original_console_nfs_backup_size = get_file_size mount_file
    end

    assert_valid_database console_nfs_backup_file
  end

  def test_nfs_database_dump
    console_nfs_dump_file = "console_full_nfs_dump.tar.gz"

    ApplianceConsoleRunner.dump console_nfs_dump_file, :nfs

    run_in_mount :nfs do |mount_point|
      mount_file = File.join(mount_point, "db_dump", console_nfs_dump_file)
      assert_file_exists mount_file
    end

    assert_valid_database console_nfs_dump_file,
  end

  def test_nfs_database_dump_excluding_custom_attributes
    console_nfs_dump_file_without_ca = "console_nfs_dump_without_custom_attributes.tar.gz"
    ApplianceConsoleRunner.dump_with_no_custom_attributes console_nfs_dump_file_without_ca, :nfs

    run_in_mount :nfs do |mount_point|
      mount_file = File.join(mount_point, "db_dump", console_nfs_dump_file_without_ca)
      assert_file_exists mount_file
      assert_valid_database console_nfs_dump_file_without_ca
    end
  end
end
