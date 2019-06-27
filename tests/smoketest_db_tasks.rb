RakeHelper.test :backup,       :local, "full_local_backup.tar.gz"
RakeHelper.test :backup_fktmp, :local, "full_local_fake_tmp_backup.tar.gz"
# RakeHelper.test :split_backup, :local, "split_local_backup.tar.gz"

RakeHelper.validate_databases "full_local_backup.tar.gz",
                              "full_local_fake_tmp_backup.tar.gz"
                              # "split_local_backup.tar.gz"


RakeHelper.test :backup,       :nfs,   "full_nfs_backup.tar.gz"
RakeHelper.test :backup_fktmp, :nfs,   "full_nfs_fake_tmp_backup.tar.gz"
# RakeHelper.test :split_backup, :nfs,   "split_nfs_backup.tar.gz"

RakeHelper.validate_databases "full_nfs_backup.tar.gz",
                              "full_nfs_fake_tmp_backup.tar.gz"
                              # "split_nfs_backup.tar.gz"


RakeHelper.test :backup,       :smb,   "full_smb_backup.tar.gz"
RakeHelper.test :backup_fktmp, :smb,   "full_smb_fake_tmp_backup.tar.gz"
# RakeHelper.test :split_backup, :smb,   "split_smb_backup.tar.gz"

RakeHelper.validate_databases "full_smb_backup.tar.gz",
                              "full_smb_fake_tmp_backup.tar.gz"
                              # "split_smb_backup.tar.gz"


RakeHelper.test :backup,       :s3,    "full_s3_backup.tar.gz"
RakeHelper.test :backup_fktmp, :s3,    "full_s3_fake_tmp_backup.tar.gz"
# RakeHelper.test :split_backup, :s3,    "split_s3_backup.tar.gz"

RakeHelper.validate_databases "full_s3_backup.tar.gz"
                              # "split_s3_backup.tar.gz"


RakeHelper.test :backup,       :ftp,   "full_ftp_backup.tar.gz"
RakeHelper.test :backup_fktmp, :ftp,   "full_ftp_fake_tmp_backup.tar.gz"
# RakeHelper.test :split_backup, :ftp,   "split_ftp_backup.tar.gz"
RakeHelper.test :backup,       :ftp,   "full_ftp_anonymous_backup.tar.gz"
RakeHelper.test :backup_fktmp, :ftp,   "full_ftp_anonymous_fake_tmp_backup.tar.gz"
# RakeHelper.test :split_backup, :ftp,   "split_ftp_anonymous_backup.tar.gz"

RakeHelper.validate_databases "full_ftp_backup.tar.gz",
                              # "split_ftp_backup.tar.gz",
                              "full_ftp_anonymous_backup.tar.gz",
                              "full_ftp_anonymous_backup.tar.gz",
                              "full_ftp_anonymous_fake_tmp_backup.tar.gz"
                              # "split_ftp_anonymous_backup.tar.gz"


RakeHelper.test :backup,       :swift,    "full_swift_backup.tar.gz"
RakeHelper.test :backup_fktmp, :swift,    "full_swift_fake_tmp_backup.tar.gz"
# RakeHelper.test :split_backup, :swift,    "split_swift_backup.tar.gz"

RakeHelper.validate_databases "full_swift_backup.tar.gz"
                              "full_swift_fake_tmp_backup.tar.gz"
                              # "split_swift_backup.tar.gz"

# --------------------------------------------- #

RakeHelper.test :dump,         :local, "full_local_dump.tar.gz"
RakeHelper.test :dump_fktmp,   :local, "full_local_fake_tmp_dump.tar.gz"
RakeHelper.test :split_dump,   :local, "split_local_dump.tar.gz"

RakeHelper.validate_databases "full_local_dump.tar.gz",
                              "full_local_fake_tmp_dump.tar.gz",
                              "split_local_dump.tar.gz"


RakeHelper.test :dump,         :nfs,   "full_nfs_dump.tar.gz"
RakeHelper.test :dump_fktmp,   :nfs,   "full_nfs_fake_tmp_dump.tar.gz"
RakeHelper.test :split_dump,   :nfs,   "split_nfs_dump.tar.gz"

RakeHelper.validate_databases "full_nfs_dump.tar.gz",
                              "full_nfs_fake_tmp_dump.tar.gz",
                              "split_nfs_dump.tar.gz"


RakeHelper.test :dump,         :smb,   "full_smb_dump.tar.gz"
RakeHelper.test :dump_fktmp,   :smb,   "full_smb_fake_tmp_dump.tar.gz"
RakeHelper.test :split_dump,   :smb,   "split_smb_dump.tar.gz"

RakeHelper.validate_databases "full_smb_dump.tar.gz",
                              "full_smb_fake_tmp_dump.tar.gz",
                              "split_smb_dump.tar.gz"


RakeHelper.test :dump,         :s3,    "full_s3_dump.tar.gz"
RakeHelper.test :dump_fktmp,   :s3,    "full_s3_fake_tmp_dump.tar.gz"
RakeHelper.test :split_dump,   :s3,    "split_s3_dump.tar.gz"

RakeHelper.validate_databases "full_s3_dump.tar.gz",
                              "full_s3_fake_tmp_dump.tar.gz",
                              "split_s3_dump.tar.gz"


RakeHelper.test :dump,         :ftp,   "full_ftp_dump.tar.gz"
RakeHelper.test :dump_fktmp,   :ftp,   "full_ftp_fake_tmp_dump.tar.gz"
RakeHelper.test :split_dump,   :ftp,   "split_ftp_dump.tar.gz"
RakeHelper.test :dump,         :ftp,   "full_ftp_anonymous_dump.tar.gz"
RakeHelper.test :dump_fktmp,   :ftp,   "full_ftp_anonymous_fake_tmp_dump.tar.gz"
RakeHelper.test :split_dump,   :ftp,   "split_ftp_anonymous_dump.tar.gz"

RakeHelper.validate_databases "full_ftp_dump.tar.gz",
                              "full_ftp_fake_tmp_dump.tar.gz",
                              "split_ftp_dump.tar.gz",
                              "full_ftp_anonymous_dump.tar.gz",
                              "full_ftp_anonymous_fake_tmp_dump.tar.gz",
                              "split_ftp_anonymous_dump.tar.gz"


RakeHelper.test :dump,         :swift, "full_swift_dump.tar.gz"
RakeHelper.test :dump_fktmp,   :swift, "full_swift_fake_tmp_dump.tar.gz"
RakeHelper.test :split_dump,   :swift, "split_swift_dump.tar.gz"

RakeHelper.validate_databases "full_swift_dump.tar.gz",
                              "full_swift_fake_tmp_dump.tar.gz",
                              "split_swift_dump.tar.gz"
