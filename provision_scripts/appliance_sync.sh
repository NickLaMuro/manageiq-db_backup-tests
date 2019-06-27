APPLIANCE_AWESOME_SPAWN_DIR=$(ls -d /usr/local/lib/ruby/gems/2.4.0/gems/awesome_spawn-* | tail -n 1)
APPLIANCE_GEMS_PENDING_DIR=$(ls -d /usr/local/lib/ruby/gems/2.4.0/bundler/gems/manageiq-gems-pending-* | tail -n 1)
APPLIANCE_CONSOLE_DIR=$(ls -d /usr/local/lib/ruby/gems/2.4.0/gems/manageiq-appliance_console-* | tail -n 1)

###### awesome_spawn changes
cp /vagrant/awesome_spawn/lib/awesome_spawn.rb \
   $APPLIANCE_AWESOME_SPAWN_DIR/lib/awesome_spawn.rb

mkdir -p $APPLIANCE_AWESOME_SPAWN_DIR/lib/core_ext
cp /vagrant/awesome_spawn/lib/core_ext/* \
   $APPLIANCE_AWESOME_SPAWN_DIR/lib/core_ext/

###### manageiq changes
cp /vagrant/manageiq/lib/evm_database_ops.rb \
   /var/www/miq/vmdb/lib/evm_database_ops.rb
cp /vagrant/manageiq/lib/tasks/evm_dba.rake \
   /var/www/miq/vmdb/lib/tasks/evm_dba.rake

###### manageiq-gems-pending "new" changes
cp /vagrant/manageiq-gems-pending/lib/gems/pending/util/postgres_admin.rb \
   $APPLIANCE_GEMS_PENDING_DIR/lib/gems/pending/util/postgres_admin.rb
cp /vagrant/manageiq-gems-pending/lib/gems/pending/util/miq_ftp_lib.rb \
   $APPLIANCE_GEMS_PENDING_DIR/lib/gems/pending/util/miq_ftp_lib.rb
cp /vagrant/manageiq-gems-pending/lib/gems/pending/util/miq_file_storage.rb \
   $APPLIANCE_GEMS_PENDING_DIR/lib/gems/pending/util/miq_file_storage.rb
cp /vagrant/manageiq-gems-pending/lib/gems/pending/util/miq_object_storage.rb \
   $APPLIANCE_GEMS_PENDING_DIR/lib/gems/pending/util/miq_object_storage.rb
cp /vagrant/manageiq-gems-pending/lib/gems/pending/util/mount/miq_generic_mount_session.rb \
   $APPLIANCE_GEMS_PENDING_DIR/lib/gems/pending/util/mount/miq_generic_mount_session.rb
cp /vagrant/manageiq-gems-pending/lib/gems/pending/util/mount/miq_local_mount_session.rb \
   $APPLIANCE_GEMS_PENDING_DIR/lib/gems/pending/util/mount/miq_local_mount_session.rb
cp /vagrant/manageiq-gems-pending/lib/gems/pending/util/mount/miq_glusterfs_session.rb \
   $APPLIANCE_GEMS_PENDING_DIR/lib/gems/pending/util/mount/miq_glusterfs_session.rb
cp /vagrant/manageiq-gems-pending/lib/gems/pending/util/mount/miq_nfs_session.rb \
   $APPLIANCE_GEMS_PENDING_DIR/lib/gems/pending/util/mount/miq_nfs_session.rb
cp /vagrant/manageiq-gems-pending/lib/gems/pending/util/mount/miq_smb_session.rb \
   $APPLIANCE_GEMS_PENDING_DIR/lib/gems/pending/util/mount/miq_smb_session.rb
mkdir -p $APPLIANCE_GEMS_PENDING_DIR/lib/gems/pending/util/object_storage
cp /vagrant/manageiq-gems-pending/lib/gems/pending/util/object_storage/miq_s3_storage.rb \
   $APPLIANCE_GEMS_PENDING_DIR/lib/gems/pending/util/object_storage/miq_s3_storage.rb
cp /vagrant/manageiq-gems-pending/lib/gems/pending/util/object_storage/miq_swift_storage.rb \
   $APPLIANCE_GEMS_PENDING_DIR/lib/gems/pending/util/object_storage/miq_swift_storage.rb
cp /vagrant/manageiq-gems-pending/lib/gems/pending/util/object_storage/miq_ftp_storage.rb \
   $APPLIANCE_GEMS_PENDING_DIR/lib/gems/pending/util/object_storage/miq_ftp_storage.rb

# aws-sdk monkey patch
mkdir -p $APPLIANCE_GEMS_PENDING_DIR/lib/gems/pending/util/extensions/aws-sdk
cp /vagrant/manageiq-gems-pending/lib/gems/pending/util/extensions/aws-sdk/s3_upload_stream_patch.rb \
   $APPLIANCE_GEMS_PENDING_DIR/lib/gems/pending/util/extensions/aws-sdk/s3_upload_stream_patch.rb

###### manageiq-appliance_console changes
cp /vagrant/manageiq-appliance_console/bin/appliance_console \
  $APPLIANCE_CONSOLE_DIR/bin/appliance_console
cp /vagrant/manageiq-appliance_console/lib/manageiq-appliance_console.rb \
  $APPLIANCE_CONSOLE_DIR/lib/manageiq-appliance_console.rb
cp /vagrant/manageiq-appliance_console/lib/manageiq/appliance_console/database_admin.rb \
  $APPLIANCE_CONSOLE_DIR/lib/manageiq/appliance_console/database_admin.rb
cp /vagrant/manageiq-appliance_console/lib/manageiq/appliance_console/database_configuration.rb \
  $APPLIANCE_CONSOLE_DIR/lib/manageiq/appliance_console/database_configuration.rb
cp /vagrant/manageiq-appliance_console/lib/manageiq/appliance_console/i18n.rb \
  $APPLIANCE_CONSOLE_DIR/lib/manageiq/appliance_console/i18n.rb
cp /vagrant/manageiq-appliance_console/lib/manageiq/appliance_console/prompts.rb \
  $APPLIANCE_CONSOLE_DIR/lib/manageiq/appliance_console/prompts.rb
cp /vagrant/manageiq-appliance_console/locales/appliance/en.yml \
  $APPLIANCE_CONSOLE_DIR/locales/appliance/en.yml
