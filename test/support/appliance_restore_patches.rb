require_relative "./appliance_secondary_db.rb"

require "linux_admin"

# Wrap LinuxAdmin::Service to handle starting/stopping postgres when this file
# is loaded.
module LinuxAdmin
  def Service.new(service_name)
    if ManageIQ::ApplianceConsole::PostgresAdmin.service_name == service_name
      ApplianceSecondaryDB
    else
      super
    end
  end
end

console_codebase_dir = Dir["/opt/manageiq/manageiq-gemset/gems/manageiq-appliance_console-*"].first
require "#{console_codebase_dir}/lib/manageiq/appliance_console/postgres_admin.rb"

ENV["APPLIANCE_PG_DATA"]    = "/opt/manageiq/postgres_restore_pg/data"
ENV["APPLIANCE_PG_SERVICE"] = "local_pg_instance"
