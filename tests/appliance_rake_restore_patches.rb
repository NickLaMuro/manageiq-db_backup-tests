require_relative "./appliance_secondary_db.rb"

require "linux_admin"

# Wrap LinuxAdmin::Service to handle starting/stopping postgres when this file
# is loaded.
module LinuxAdmin
  def Service.new(service_name)
    if PostgresAdmin.service_name == service_name
      ApplianceSecondaryDB
    else
      super
    end
  end
end

require "postgres_admin"

# Patch PostgresAdmin to use different user/group
class PostgresAdmin
  def self.user
    "vagrant".freeze
  end
end

ENV["APPLIANCE_PG_DATA"]    = "/opt/manageiq/postgres_restore_pg/data"
ENV["APPLIANCE_PG_SERVICE"] = "local_pg_instance"
