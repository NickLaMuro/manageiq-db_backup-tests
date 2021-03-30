require 'yaml'
require 'erb'

require 'active_record'
require 'manageiq-password'

require_relative './vmdb_helper.rb'

module DbConnection
  module_function

  def configure
    miq_root = if Dir.exist? VmdbHelper::MIQ_ROOT
                 VmdbHelper::MIQ_ROOT
               else # assume running locally
                 File.expand_path File.join(__FILE__, *%w[.. .. manageiq])
               end
    ENV["KEY_ROOT"] = File.join miq_root, "certs"

    yaml = File.read File.join(miq_root, 'config', 'database.yml')
    data = YAML.load ERB.new(yaml).result

    configurations = { "default" => data["production"].dup }
    configurations["default"]["password"] = MiqPassword.try_decrypt(configurations["default"]["password"])

    ActiveRecord::Base.configurations = configurations
  end
end
