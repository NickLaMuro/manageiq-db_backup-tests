original_console_backup_size = nil
console_local_backup_file = "console_full_local_backup.tar.gz"
testing "appliance_console:  Local Database Backup" do
  ApplianceConsoleRunner.backup console_local_backup_file

  assert_file_exists console_local_backup_file
  original_console_backup_size = get_file_size console_local_backup_file
end

# --------------------------------------------- #

# console_split_local_backup_file = "console_split_local_backup.tar.gz"
# testing "appliance_console:  Split Local Database Backup" do
#   ApplianceConsoleRunner.backup console_split_local_backup_file, :local, "2M"

#   assert_split_files console_split_local_backup_file, 2 * MEGABYTES, original_console_backup_size, 200
# end

# --------------------------------------------- #

testing "appliance_console:  Local Database Backups are valid" do
  DbTestCase.valid_database? console_local_backup_file
#                              console_split_local_backup_file
end

# --------------------------------------------- #

console_local_backup_file_with_subdir = "tmp/subdir/console_full_local_backup.tar.gz"
testing "appliance_console:  Local Database Backup in subdir" do
  ApplianceConsoleRunner.backup console_local_backup_file_with_subdir

  assert_file_exists console_local_backup_file_with_subdir
  DbTestCase.valid_database? console_local_backup_file_with_subdir
end

# --------------------------------------------- #

original_console_nfs_backup_size = nil
console_nfs_backup_file = "console_full_nfs_backup.tar.gz"
testing "appliance_console:  NFS Database Backup" do
  ApplianceConsoleRunner.backup console_nfs_backup_file, :nfs

  run_in_mount :nfs do |mount_point|
    mount_file = File.join(mount_point, "db_backup", console_nfs_backup_file)
    assert_file_exists mount_file
    original_console_nfs_backup_size = get_file_size mount_file
  end
end

# --------------------------------------------- #

# console_split_nfs_backup_file = "console_split_nfs_backup.tar.gz"
# testing "appliance_console:  Split NFS Database Backup" do
#   ApplianceConsoleRunner.backup console_split_nfs_backup_file, :nfs, "2M"

#   run_in_mount :nfs do |mount_point|
#     mount_file = File.join(mount_point, "db_backup", console_split_nfs_backup_file)
#     assert_split_files mount_file, 2 * MEGABYTES, original_console_nfs_backup_size, 200
#   end
# end

# --------------------------------------------- #

testing "appliance_console:  NFS Database Backups are valid" do
  DbTestCase.valid_database? console_nfs_backup_file
#                              console_split_nfs_backup_file
end


# --------------------------------------------- #

original_console_smb_backup_size = nil
console_smb_backup_file = "console_full_smb_backup.tar.gz"
testing "appliance_console:  SMB Database Backup" do
  ApplianceConsoleRunner.backup console_smb_backup_file, :smb

  run_in_mount :smb do |mount_point|
    mount_file = File.join(mount_point, "db_backup", console_smb_backup_file)
    assert_file_exists mount_file
    original_console_smb_backup_size = get_file_size mount_file
  end
end

# --------------------------------------------- #

# console_split_smb_backup_file = "console_split_smb_backup.tar.gz"
# testing "appliance_console:  Split SMB Database Backup" do
#   ApplianceConsoleRunner.backup console_split_smb_backup_file, :smb, "2M"

#   run_in_mount :smb do |mount_point|
#     mount_file = File.join(mount_point, "db_backup", console_split_smb_backup_file)
#     assert_split_files mount_file, 2 * MEGABYTES, original_console_smb_backup_size, 200
#   end
# end

# --------------------------------------------- #

testing "appliance_console:  SMB Database Backups are valid" do
  DbTestCase.valid_database? console_smb_backup_file
#                              console_split_smb_backup_file
end


# --------------------------------------------- #

original_console_s3_backup_size = nil
console_s3_backup_file = "console_full_s3_backup.tar.gz"
testing "appliance_console:  S3 Database Backup" do
  ApplianceConsoleRunner.backup console_s3_backup_file, :s3

  s3_file = File.join("db_backup", console_s3_backup_file)
  assert_file_exists s3_file
  original_console_s3_backup_size = get_file_size s3_file

  # Download DB to NFS share for validation later
  run_in_mount(:nfs) { |mnt| S3Helper.download_to mnt, s3_file }
end

# --------------------------------------------- #

# console_split_s3_backup_file = "console_split_s3_backup.tar.gz"
# testing "appliance_console:  Split S3 Database Backup" do
#   ApplianceConsoleRunner.backup console_split_s3_backup_file, :s3, "2M"

#   s3_file = File.join("db_backup", console_split_s3_backup_file)
#   assert_file_exists s3_file
#   assert_split_files s3_file, 2 * MEGABYTES, original_console_s3_backup_size, 300

#   # Download DB to NFS share for validation later
#   run_in_mount(:nfs) { |mnt| S3Helper.download_to mnt, s3_file }
# end

# --------------------------------------------- #

testing "appliance_console:  S3 Database Backups are valid" do
  DbTestCase.valid_database? console_s3_backup_file
#                              console_split_s3_backup_file
end


# --------------------------------------------- #

original_console_ftp_backup_size = nil
console_ftp_backup_file = "console_full_ftp_backup.tar.gz"
testing "appliance_console:  FTP Database Backup" do
  ApplianceConsoleRunner.backup console_ftp_backup_file, :ftp

  assert_file_exists console_ftp_backup_file
  original_console_ftp_backup_size = get_file_size console_ftp_backup_file
end

# --------------------------------------------- #

# console_split_ftp_backup_file = "console_split_ftp_backup.tar.gz"
# testing "appliance_console:  Split FTP Database Backup" do
#   ftp_file = console_split_ftp_backup_file

#   ApplianceConsoleRunner.backup ftp_file, :ftp, "2M"

#   assert_file_exists ftp_file
#   assert_split_files ftp_file, 2 * MEGABYTES, original_console_ftp_backup_size, 300
# end

original_console_ftp_anonymous_backup_size = nil
console_ftp_anonymous_backup_file = "console_full_ftp_anonymous_backup.tar.gz"
testing "appliance_console:  Anonymous FTP Database Backup" do
  ApplianceConsoleRunner.backup console_ftp_anonymous_backup_file, :ftp_anonymous

  assert_file_exists console_ftp_anonymous_backup_file
  original_console_ftp_anonymous_backup_size = get_file_size console_ftp_anonymous_backup_file
end

# --------------------------------------------- #

# console_split_ftp_anonymous_backup_file = "console_split_ftp_anonymous_backup.tar.gz"
# testing "appliance_console:  Anonymous Split FTP Database Backup" do
#   ftp_file = console_split_ftp_anonymous_backup_file

#   ApplianceConsoleRunner.backup ftp_file, :ftp_anonymous, "2M"

#   assert_file_exists ftp_file
#   assert_split_files ftp_file, 2 * MEGABYTES, original_console_ftp_anonymous_backup_size, 200
# end

# --------------------------------------------- #

testing "appliance_console:  Anonymous FTP Database Backups are valid" do
  DbTestCase.valid_database? console_ftp_backup_file,
#                              console_split_ftp_backup_file,
                             console_ftp_anonymous_backup_file
#                              console_split_ftp_anonymous_backup_file
end

# --------------------------------------------- #

original_console_dump_size = nil
console_local_dump_file = "console_full_local_dump.tar.gz"
testing "appliance_console:  Local Database Dump" do
  ApplianceConsoleRunner.dump console_local_dump_file

  assert_file_exists console_local_dump_file
  original_console_dump_size = get_file_size console_local_dump_file
end

# --------------------------------------------- #

console_split_local_dump_file = "console_split_local_dump.tar.gz"
testing "appliance_console:  Split Local Database Dump" do
  ApplianceConsoleRunner.dump console_split_local_dump_file, :local, "2M"

  assert_split_files console_split_local_dump_file, 2 * MEGABYTES, original_console_dump_size, 200
end

# --------------------------------------------- #

console_local_dump_file_without_ca = "console_full_local_dump_without_custom_attributes.tar.gz"
testing "appliance_console:  Local Database Dump excluding custom_attributes" do
  ApplianceConsoleRunner.dump_with_no_custom_attributes console_local_dump_file_without_ca

  assert_file_exists console_local_dump_file_without_ca
  DbTestCase.no_custom_attributes? console_local_dump_file_without_ca
end

# --------------------------------------------- #

testing "appliance_console:  Local Database Dumps are valid" do
  DbTestCase.valid_database? console_local_dump_file,
                             console_split_local_dump_file
end

# --------------------------------------------- #

console_local_dump_file_with_subdir = "tmp/subdir/console_full_local_dump.tar.gz"
testing "appliance_console:  Local Database Dump in subdir" do
  ApplianceConsoleRunner.dump console_local_dump_file_with_subdir

  assert_file_exists console_local_dump_file_with_subdir
  DbTestCase.valid_database? console_local_dump_file_with_subdir
end

# --------------------------------------------- #

original_console_nfs_dump_size = nil
console_nfs_dump_file = "console_full_nfs_dump.tar.gz"
testing "appliance_console:  NFS Database Dump" do
  ApplianceConsoleRunner.dump console_nfs_dump_file, :nfs

  run_in_mount :nfs do |mount_point|
    mount_file = File.join(mount_point, "db_dump", console_nfs_dump_file)
    assert_file_exists mount_file
    original_console_nfs_dump_size = get_file_size mount_file
  end
end

# --------------------------------------------- #

console_split_nfs_dump_file = "console_split_nfs_dump.tar.gz"
testing "appliance_console:  Split NFS Database Dump" do
  ApplianceConsoleRunner.dump console_split_nfs_dump_file, :nfs, "2M"

  run_in_mount :nfs do |mount_point|
    mount_file = File.join(mount_point, "db_dump", console_split_nfs_dump_file)
    assert_split_files mount_file, 2 * MEGABYTES, original_console_nfs_dump_size, 200
  end
end

# --------------------------------------------- #

console_nfs_dump_file_without_ca = "console_nfs_dump_without_custom_attributes.tar.gz"
testing "appliance_console:  NFS Database Dump excluding custom_attributes" do
  ApplianceConsoleRunner.dump_with_no_custom_attributes console_nfs_dump_file_without_ca, :nfs

  run_in_mount :nfs do |mount_point|
    mount_file = File.join(mount_point, "db_dump", console_nfs_dump_file_without_ca)
    assert_file_exists mount_file
    DbTestCase.no_custom_attributes? console_nfs_dump_file_without_ca
  end
end

# --------------------------------------------- #

testing "appliance_console:  NFS Database Dumps are valid" do
  DbTestCase.valid_database? console_nfs_dump_file,
                             console_split_nfs_dump_file
end


# --------------------------------------------- #

original_console_smb_dump_size = nil
console_smb_dump_file = "console_full_smb_dump.tar.gz"
testing "appliance_console:  SMB Database Dump" do
  ApplianceConsoleRunner.dump console_smb_dump_file, :smb

  run_in_mount :smb do |mount_point|
    mount_file = File.join(mount_point, "db_dump", console_smb_dump_file)
    assert_file_exists mount_file
    original_console_smb_dump_size = get_file_size mount_file
  end
end

# --------------------------------------------- #

console_split_smb_dump_file = "console_split_smb_dump.tar.gz"
testing "appliance_console:  Split SMB Database Dump" do
  ApplianceConsoleRunner.dump console_split_smb_dump_file, :smb, "2M"

  run_in_mount :smb do |mount_point|
    mount_file = File.join(mount_point, "db_dump", console_split_smb_dump_file)
    assert_split_files mount_file, 2 * MEGABYTES, original_console_smb_dump_size, 200
  end
end

# --------------------------------------------- #

console_smb_dump_file_without_ca = "console_smb_dump_without_custom_attributes.tar.gz"
testing "appliance_console:  SMB Database Dump excluding custom_attributes" do
  ApplianceConsoleRunner.dump_with_no_custom_attributes console_smb_dump_file_without_ca, :smb

  run_in_mount :smb do |mount_point|
    mount_file = File.join(mount_point, "db_dump", console_smb_dump_file_without_ca)
    assert_file_exists mount_file
    DbTestCase.no_custom_attributes? console_smb_dump_file_without_ca
  end
end

# --------------------------------------------- #

testing "appliance_console:  SMB Database Dumps are valid" do
  DbTestCase.valid_database? console_smb_dump_file,
                             console_split_smb_dump_file
end


# --------------------------------------------- #

original_console_s3_dump_size = nil
console_s3_dump_file = "console_full_s3_dump.tar.gz"
testing "appliance_console:  S3 Database Dump" do
  ApplianceConsoleRunner.dump console_s3_dump_file, :s3

  s3_file = File.join("db_dump", console_s3_dump_file)
  assert_file_exists s3_file
  original_console_s3_dump_size = get_file_size s3_file

  # Download DB to NFS share for validation later
  run_in_mount(:nfs) { |mnt| S3Helper.download_to mnt, s3_file }
end

# --------------------------------------------- #

console_split_s3_dump_file = "console_split_s3_dump.tar.gz"
testing "appliance_console:  Split S3 Database Dump" do
  ApplianceConsoleRunner.dump console_split_s3_dump_file, :s3, "2M"

  s3_file = File.join("db_dump", console_split_s3_dump_file)
  assert_file_exists s3_file
  assert_split_files s3_file, 2 * MEGABYTES, original_console_s3_dump_size, 300

  # Download DB to NFS share for validation later
  run_in_mount(:nfs) { |mnt| S3Helper.download_to mnt, s3_file }
end

# --------------------------------------------- #

testing "appliance_console:  S3 Database Dumps are valid" do
  DbTestCase.valid_database? console_s3_dump_file,
                             console_split_s3_dump_file
end


# --------------------------------------------- #

original_console_ftp_dump_size = nil
console_ftp_dump_file = "console_full_ftp_dump.tar.gz"
testing "appliance_console:  FTP Database Dump" do
  ApplianceConsoleRunner.dump console_ftp_dump_file, :ftp

  assert_file_exists console_ftp_dump_file
  original_console_ftp_dump_size = get_file_size console_ftp_dump_file
end

# --------------------------------------------- #

console_split_ftp_dump_file = "console_split_ftp_dump.tar.gz"
testing "appliance_console:  Split FTP Database Dump" do
  ftp_file = console_split_ftp_dump_file

  ApplianceConsoleRunner.dump ftp_file, :ftp, "2M"
  assert_split_files ftp_file, 2 * MEGABYTES, original_console_ftp_dump_size, 200
end

original_console_ftp_anonymous_dump_size = nil
console_ftp_anonymous_dump_file = "console_full_ftp_anonymous_dump.tar.gz"
testing "appliance_console:  Anonymous FTP Database Dump" do
  ApplianceConsoleRunner.dump console_ftp_anonymous_dump_file, :ftp_anonymous

  assert_file_exists console_ftp_anonymous_dump_file
  original_console_ftp_anonymous_dump_size = get_file_size console_ftp_anonymous_dump_file
end

# --------------------------------------------- #

console_split_ftp_anonymous_dump_file = "console_split_ftp_anonymous_dump.tar.gz"
testing "appliance_console:  Anonymous Split FTP Database Dump" do
  ftp_file = console_split_ftp_anonymous_dump_file

  ApplianceConsoleRunner.dump ftp_file, :ftp_anonymous, "2M"
  assert_split_files ftp_file, 2 * MEGABYTES, original_console_ftp_anonymous_dump_size, 300
end

# --------------------------------------------- #

testing "appliance_console:  FTP Database Dumps are valid" do
  DbTestCase.valid_database? console_ftp_dump_file,
                             console_split_ftp_dump_file,
                             console_ftp_anonymous_dump_file,
                             console_split_ftp_anonymous_dump_file
end
