APPLIANCE_CONSOLE_DIR=$(ls -d /opt/manageiq/manageiq-gemset/gems/manageiq-appliance_console-* | tail -n 1)
GEMS_PENDING_CONSOLE_DIR=$(ls -d /opt/manageiq/manageiq-gemset/gems/manageiq-gems-pending-* | tail -n 1)

###### manageiq changes
# cp /vagrant/manageiq/lib/evm_database_ops.rb \
#    /var/www/miq/vmdb/lib/evm_database_ops.rb
# cp /vagrant/manageiq/lib/tasks/evm_dba.rake \
#    /var/www/miq/vmdb/lib/tasks/evm_dba.rake

###### manageiq-appliance_console changes
cp /vagrant/manageiq-appliance_console/bin/appliance_console \
  $APPLIANCE_CONSOLE_DIR/bin/appliance_console
cp /vagrant/manageiq-appliance_console/lib/manageiq-appliance_console.rb \
  $APPLIANCE_CONSOLE_DIR/lib/manageiq-appliance_console.rb
cp /vagrant/manageiq-appliance_console/lib/manageiq/appliance_console/certificate_authority.rb \
  $APPLIANCE_CONSOLE_DIR//lib/manageiq/appliance_console/certificate_authority.rb
cp /vagrant/manageiq-appliance_console/lib/manageiq/appliance_console/cli.rb \
  $APPLIANCE_CONSOLE_DIR//lib/manageiq/appliance_console/cli.rb
cp /vagrant/manageiq-appliance_console/lib/manageiq/appliance_console/database_admin.rb \
  $APPLIANCE_CONSOLE_DIR/lib/manageiq/appliance_console/database_admin.rb
cp /vagrant/manageiq-appliance_console/lib/manageiq/appliance_console/database_configuration.rb \
  $APPLIANCE_CONSOLE_DIR/lib/manageiq/appliance_console/database_configuration.rb
cp /vagrant/manageiq-appliance_console/lib/manageiq/appliance_console/database_replication.rb \
  $APPLIANCE_CONSOLE_DIR/lib/manageiq/appliance_console/database_replication.rb
cp /vagrant/manageiq-appliance_console/lib/manageiq/appliance_console/database_replication_standby.rb \
  $APPLIANCE_CONSOLE_DIR/lib/manageiq/appliance_console/database_replication_standby.rb
cp /vagrant/manageiq-appliance_console/locales/appliance/en.yml \
  $APPLIANCE_CONSOLE_DIR/locales/appliance/en.yml
cp /vagrant/manageiq-appliance_console/lib/manageiq/appliance_console/i18n.rb \
  $APPLIANCE_CONSOLE_DIR/lib/manageiq/appliance_console/i18n.rb
cp /vagrant/manageiq-appliance_console/lib/manageiq/appliance_console/internal_database_configuration.rb \
  $APPLIANCE_CONSOLE_DIR/lib/manageiq/appliance_console/internal_database_configuration.rb
cp /vagrant/manageiq-appliance_console/lib/manageiq/appliance_console/message_configuration.rb \
  $APPLIANCE_CONSOLE_DIR//lib/manageiq/appliance_console/message_configuration.rb
cp /vagrant/manageiq-appliance_console/lib/manageiq/appliance_console/message_configuration_client.rb \
  $APPLIANCE_CONSOLE_DIR//lib/manageiq/appliance_console/message_configuration_client.rb
cp /vagrant/manageiq-appliance_console/lib/manageiq/appliance_console/message_configuration_server.rb \
  $APPLIANCE_CONSOLE_DIR//lib/manageiq/appliance_console/message_configuration_server.rb
cp /vagrant/manageiq-appliance_console/lib/manageiq/appliance_console/postgres_admin.rb \
  $APPLIANCE_CONSOLE_DIR/lib/manageiq/appliance_console/postgres_admin.rb
cp /vagrant/manageiq-appliance_console/lib/manageiq/appliance_console/prompts.rb \
  $APPLIANCE_CONSOLE_DIR/lib/manageiq/appliance_console/prompts.rb
cp /vagrant/manageiq-appliance_console/lib/manageiq/appliance_console/utilities.rb \
  $APPLIANCE_CONSOLE_DIR/lib/manageiq/appliance_console/utilities.rb

###### manageiq-gems-pending changes
cp /vagrant/manageiq-gems-pending/lib/gems/pending/util/mount/miq_generic_mount_session.rb \
  $GEMS_PENDING_CONSOLE_DIR/lib/gems/pending/util/mount/miq_generic_mount_session.rb
