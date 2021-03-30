require "test_helper"

class LocalBackupTest < BaseBackupTest
  def test_local_database_backup
    console_local_backup_file = "console_full_local_backup.tar.gz"

    ApplianceConsoleRunner.backup console_local_backup_file

    assert_file_exists console_local_backup_file
    assert_valid_database console_local_backup_file
  end

  def test_local_database_backup_in_subdir
    console_local_backup_file_with_subdir = "tmp/subdir/console_full_local_backup.tar.gz"

    ApplianceConsoleRunner.backup console_local_backup_file_with_subdir

    assert_file_exists console_local_backup_file_with_subdir
    assert_valid_database console_local_backup_file_with_subdir
  end

  def test_local_database_dump
    console_local_dump_file = "console_full_local_dump.tar.gz"

    ApplianceConsoleRunner.dump console_local_dump_file

    assert_file_exists console_local_dump_file
    assert_valid_database console_local_dump_file
  end

  def test_local_database_dump_excluding_custom_attributes
    console_local_dump_file_without_ca = "console_full_local_dump_without_custom_attributes.tar.gz"

    ApplianceConsoleRunner.dump_with_no_custom_attributes console_local_dump_file_without_ca

    assert_file_exists           console_local_dump_file_without_ca
    refute_has_custom_attributes console_local_dump_file_without_ca
  end

  def test_local_database_dump_in_subdir
    console_local_dump_file_with_subdir = "tmp/subdir/console_full_local_dump.tar.gz"
    ApplianceConsoleRunner.dump console_local_dump_file_with_subdir

    assert_file_exists console_local_dump_file_with_subdir
    assert_valid_database console_local_dump_file_with_subdir
  end

  def teardown
    ApplianceConsoleRunner::Current.instance = nil
  end
end
