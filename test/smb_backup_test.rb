require "test_helper"

class SMBBackupTest < BaseBackupTest

  def test_smb_database_backup
    console_smb_backup_file = "console_full_smb_backup.tar.gz"
    ApplianceConsoleRunner.backup console_smb_backup_file, :smb

    run_in_mount :smb do |mount_point|
      mount_file = File.join(mount_point, "db_backup", console_smb_backup_file)
      assert_file_exists mount_file
      original_console_smb_backup_size = get_file_size mount_file
    end

    assert_valid_database console_smb_backup_file
  end

  def test_smb_database_dump
    console_smb_dump_file = "console_full_smb_dump.tar.gz"

    ApplianceConsoleRunner.dump console_smb_dump_file, :smb

    run_in_mount :smb do |mount_point|
      mount_file = File.join(mount_point, "db_dump", console_smb_dump_file)
      assert_file_exists mount_file
    end

    assert_valid_database console_smb_dump_file,
  end

  def test_smb_database_dump_excluding_custom_attributes
    console_smb_dump_file_without_ca = "console_smb_dump_without_custom_attributes.tar.gz"
    ApplianceConsoleRunner.dump_with_no_custom_attributes console_smb_dump_file_without_ca, :smb

    run_in_mount :smb do |mount_point|
      mount_file = File.join(mount_point, "db_dump", console_smb_dump_file_without_ca)
      assert_file_exists mount_file
      assert_valid_database console_smb_dump_file_without_ca
    end
  end
end
