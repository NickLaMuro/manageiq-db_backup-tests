MIQ_GH_URL_BASE=https://raw.githubusercontent.com/ManageIQ
APPLIANCE_AWESOME_SPAWN_DIR=$(ls -d /usr/local/lib/ruby/gems/2.3.0/gems/awesome_spawn-* | tail -n 1)
APPLIANCE_GEMS_PENDING_DIR=$(ls -d /usr/local/lib/ruby/gems/2.3.0/bundler/gems/manageiq-gems-pending-* | tail -n 1)
APPLIANCE_CONSOLE_DIR=$(ls -d /usr/local/lib/ruby/gems/2.3.0/gems/manageiq-appliance_console-* | tail -n 1)

###### undo awesome_spawn changes
curl --silent "${MIQ_GH_URL_BASE}/awesome_spawn/master/lib/awesome_spawn.rb" > $APPLIANCE_AWESOME_SPAWN_DIR/lib/awesome_spawn.rb
rm -rf $APPLIANCE_AWESOME_SPAWN_DIR/lib/core_ext

###### undo manageiq changes
MIQ_URL="${MIQ_GH_URL_BASE}/manageiq/master/"

curl --silent "${MIQ_URL}/lib/evm_database_ops.rb" > /var/www/miq/vmdb/lib/evm_database_ops.rb
curl --silent "${MIQ_URL}/lib/tasks/evm_dba.rake"  > /var/www/miq/vmdb/lib/tasks/evm_dba.rake

###### undo manageiq-gems-pending changes
GEMS_PENDING_URL="${MIQ_GH_URL_BASE}/manageiq-gems-pending/gaprindashvili/lib/gems/pending/util"

curl --silent "${GEMS_PENDING_URL}/postgres_admin.rb"                  > $APPLIANCE_GEMS_PENDING_DIR/lib/gems/pending/util/postgres_admin.rb
curl --silent "${GEMS_PENDING_URL}/mount/miq_generic_mount_session.rb" > $APPLIANCE_GEMS_PENDING_DIR/lib/gems/pending/util/mount/miq_generic_mount_session.rb
curl --silent "${GEMS_PENDING_URL}/mount/miq_glusterfs_session.rb"     > $APPLIANCE_GEMS_PENDING_DIR/lib/gems/pending/util/mount/miq_glusterfs_session.rb
curl --silent "${GEMS_PENDING_URL}/mount/miq_nfs_session.rb"           > $APPLIANCE_GEMS_PENDING_DIR/lib/gems/pending/util/mount/miq_nfs_session.rb
curl --silent "${GEMS_PENDING_URL}/mount/miq_smb_session.rb"           > $APPLIANCE_GEMS_PENDING_DIR/lib/gems/pending/util/mount/miq_smb_session.rb

rm -rf $APPLIANCE_GEMS_PENDING_DIR/lib/gems/pending/util/object_storage
rm -rf $APPLIANCE_GEMS_PENDING_DIR/lib/gems/pending/util/miq_ftp_lib.rb
rm -rf $APPLIANCE_GEMS_PENDING_DIR/lib/gems/pending/util/miq_file_storage.rb
rm -rf $APPLIANCE_GEMS_PENDING_DIR/lib/gems/pending/util/miq_object_storage.rb
rm -rf $APPLIANCE_GEMS_PENDING_DIR/lib/gems/pending/util/mount/miq_local_mount_session.rb
rm -rf $APPLIANCE_GEMS_PENDING_DIR/lib/gems/pending/util/extensions/aws-sdk

###### undo manageiq-appliance_console changes
CONSOLE_URL="${MIQ_GH_URL_BASE}/manageiq-appliance_console/v2.0.3"

curl --silent "${CONSOLE_URL}/bin/appliance_console"                                    > $APPLIANCE_CONSOLE_DIR/bin/appliance_console
curl --silent "${CONSOLE_URL}/lib/manageiq-appliance_console.rb"                        > $APPLIANCE_CONSOLE_DIR/lib/manageiq-appliance_console.rb
curl --silent "${CONSOLE_URL}/lib/manageiq/appliance_console/database_admin.rb"         > $APPLIANCE_CONSOLE_DIR/lib/manageiq/appliance_console/database_admin.rb
curl --silent "${CONSOLE_URL}/lib/manageiq/appliance_console/database_configuration.rb" > $APPLIANCE_CONSOLE_DIR/lib/manageiq/appliance_console/database_configuration.rb
curl --silent "${CONSOLE_URL}/lib/manageiq/appliance_console/i18n.rb"                   > $APPLIANCE_CONSOLE_DIR/lib/manageiq/appliance_console/i18n.rb
curl --silent "${CONSOLE_URL}/lib/manageiq/appliance_console/prompts.rb"                > $APPLIANCE_CONSOLE_DIR/lib/manageiq/appliance_console/prompts.rb
curl --silent "${CONSOLE_URL}/locales/appliance/en.yml"                                 > $APPLIANCE_CONSOLE_DIR/locales/appliance/en.yml
