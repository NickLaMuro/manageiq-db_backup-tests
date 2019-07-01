require 'yaml'
require 'erb'
require 'shellwords'
require 'active_record'

require_relative "./smoketest_rake_helper.rb"
require_relative "./smoketest_ssh_helper.rb"
require_relative "./smoketest_validator.rb"
require_relative "./appliance_secondary_db.rb"

require 'manageiq-password'

default_root = File.join "", *%w[var www miq vmdb]
miq_root     = if Dir.exists? File.join(*default_root)
                 default_root
               else # assume running locally
                 File.expand_path File.join(__FILE__, *%w[.. .. manageiq])
               end
ENV["KEY_ROOT"] = File.join miq_root, "certs"

yaml = File.read File.join(miq_root, 'config', 'database.yml')
data = YAML.load ERB.new(yaml).result

configurations = { "default" => data["production"].dup }
configurations["default"]["password"] = MiqPassword.try_decrypt(configurations["default"]["password"])

ActiveRecord::Base.configurations = configurations

class DbValidator
  include TestHelper
  include MountHelper

  RAKE_RESTORE_PATCHES = "/vagrant/tests/appliance_rake_restore_patches.rb"

  attr_reader :dbname, :restore_type, :rake_location, :split

  def self.validate db
    new(db).matches_origial?
  end

  def self.no_custom_attributes? db
    !new(db).has_custom_attributes?
  end

  def self.default_vm_count
    @default_vm_count ||= default_connection.vm_count
  end

  def self.default_custom_attribute_count
    @default_custom_attribute_count ||= default_connection.custom_attribute_count
  end

  def self.default_connection
    @default_connection ||= new
  end

  def self.defaults
    @defaults ||= default_connection.counts
  end

  def initialize db = :default 
    @db = db

    # Default DB doesn't need to be restored
    unless @db == :default
      set_restore_vars
      initialize_db_configuration
      reload_db
    end
  end

  def matches_origial?
    counts == self.class.defaults
  end

  def counts
    {
      :vms               => vm_count,
      :custom_attributes => custom_attribute_count
    }
  end

  def vm_count
    with_connection { ActiveRecord::Base.connection.select_rows("SELECT COUNT(id) FROM vms")[0][0] }
  end

  def custom_attribute_count
    with_connection { ActiveRecord::Base.connection.select_rows("SELECT COUNT(id) FROM custom_attributes")[0][0] }
  end

  def has_custom_attributes?
    custom_attribute_count > 0
  end

  private

  def with_connection
    ActiveRecord::Base.establish_connection @db.to_sym
    # puts ActiveRecord::Base.connection_config.inspect
    yield
  ensure
    ActiveRecord::Base.remove_connection
  end

  def initialize_db_configuration
    unless @db == :default
      new_configuration = ActiveRecord::Base.configurations['default'].dup
      new_configuration["database"] = dump_database_name if @db =~ /dump/
      if not split and not TestConfig.skip_restore and restore_type == "backup"
        new_configuration["port"]   = "5555"
      else
        new_configuration["host"]   = "192.168.50.11"
      end
      ActiveRecord::Base.configurations[@db.to_s] = new_configuration
    end
  end

  def reload_db
    upload_local_db if @db =~ /local/
    if @db =~ /backup/
      load_database_backup
    elsif @db =~ /dump/
      load_database_dump
    end
  end

  VMDB_DIR_ARRAY = %w[var www miq vmdb].unshift("").freeze
  def upload_local_db
    dir = @db =~ /backup/ ? "db_backup" : "db_dump"
    dir = File.dirname File.join(dir, @db.split(File::SEPARATOR) - VMDB_DIR_ARRAY)
    SSHHelper.with_session do |ssh|
      Dir["/var/www/miq/vmdb/#{@db}*"].each do |file|
        ssh.scp.upload! file, "/home/vagrant/"
      end

      ssh.exec! "sudo mkdir -p /var/nfs/#{dir}"
      ssh.exec! "sudo mv /home/vagrant/#{File.basename @db}* /var/nfs/#{dir}"
    end
  end

  DB_BACKUP_RESTORE_TEMPLATE = [
    %Q{sudo rc-service -q postgresql stop},
    %Q{sudo /bin/bash -c 'rm -rf /var/lib/postgresql/10/data/*'},
    %Q{ls %s* | sort | sudo xargs cat | sudo tar -xz -C /var/lib/postgresql/10/data/},
    %Q{sudo sed -i "s/^.*\\/etc\\/manageiq\\/postgresql.conf.d.*$/listen_addresses = '*'/" /var/lib/postgresql/10/data/postgresql.conf},
    %Q{sudo cp /var/lib/postgresql/10/data/pg_hba.conf /var/lib/postgresql/10/data/pg_hba.conf.bak},
    %Q{sudo /bin/sh -c "head -n 3 /var/lib/postgresql/10/data/pg_hba.conf.bak > /var/lib/postgresql/10/data/pg_hba.conf"},
    %Q{sudo /bin/sh -c "echo 'host all all 192.168.50.10/0 md5' >> /var/lib/postgresql/10/data/pg_hba.conf"},
    %Q{sudo rc-service -q postgresql start}
  ].join(" && ").freeze
  def load_database_backup
    if split || TestConfig.skip_restore
      filepath = share_filepath_for :backup
      SSHHelper.run_commands DB_BACKUP_RESTORE_TEMPLATE % filepath
    else
      ApplianceSecondaryDB.reset_db
      RakeHelper.run_rake :restore, rake_location, @db,
                          :dbname        => dbname,
                          :port          => "5555",
                          :hostname      => "localhost",
                          :username      => "root",
                          :password      => "smartvm",
                          :rake_cmd_args => { :require => RAKE_RESTORE_PATCHES }
    end
  end

  DB_BACKUP_DUMP_TEMPLATE = [
    %Q{sudo psql -qc 'DROP DATABASE IF EXISTS %s' postgres &> /dev/null},
    %Q{sudo psql -qc 'CREATE DATABASE %s' postgres},
    %Q{ls %s* | sort | sudo xargs cat | sudo pg_restore -d %s}
  ].join(" && ").freeze
  def load_database_dump
    if split || TestConfig.skip_restore
      filepath = share_filepath_for :dump
      SSHHelper.run_commands DB_BACKUP_DUMP_TEMPLATE % [dbname, dbname, filepath, dbname]
    else
      RakeHelper.run_rake :restore, rake_location, @db,
                          :dbname   => dbname,
                          :hostname => SHARE_IP,
                          :username => "root",
                          :password => "smartvm"
    end
  end

  def share_filepath_for action
    filepath = ["db_#{action}", "#{@db}*"]
    if @db =~ /ftp/
      filepath.insert 0, FTPHelper.base_dir_for(filepath.last)
    elsif @db =~ /_(nfs|local|s3|swift)_/
      filepath.insert 0, *%w[var nfs]
    elsif @db =~ /smb/
      filepath.insert 0, *%w[var smb]
    end
    File.join "", *filepath
  end

  def dump_database_name
    File.basename @db.to_s.split('.').first
  end

  def set_restore_vars
    @dbname = dump_database_name
    @rake_location, @restore_type, _, @split = parse_db_filename dbname
  end
end

class DbTestCase
  include TestHelper

  attr_reader :backups_to_validate

  def self.validate *dbs
    new(*dbs).validate
  end

  # Similar to the above, but doesn't run inside of a `testing` block
  def self.valid_database? *dbs
    new(*dbs).valid_databases?
  end

  def self.no_custom_attributes? *dbs
    new(*dbs).no_custom_attributes?
  end

  def initialize *dbs
    @backups_to_validate = dbs
  end

  def validate
    testing validation_message do
      valid_databases?
    end
  end

  def valid_databases?
    backups_to_validate.each { |db| assert_valid_database db }
  end

  def no_custom_attributes?
    backups_to_validate.each { |db| assert_no_custom_attributes db }
  end

  private

  def validation_message
    message = nil
    backups_to_validate.each do |filename|
      location, type, _ = parse_db_filename filename

      new_message = "#{location} #{type}s are valid"
      if message && message != new_message
        raise ArgumentError, "use one backup type/location at a time"
      end
      message ||= new_message
    end
    message
  end

  def assert_no_custom_attributes backup_file
    DbValidator.no_custom_attributes?(backup_file) || fail("custom_attributes is present in #{backup_file}")
  end

  def assert_valid_database backup_file
    if run_db_validation? backup_file
      DbValidator.validate(backup_file) || raise("invalid DB (call 'fail' below)")
    end
  rescue => e
    fail <<-ERR.gsub(/^ {4}/, '') + e.backtrace.map { |l| "    #{l}" }.join("\n")
      #{backup_file} was not a valid database
        
        Error:  #{e.message}
    ERR
  end

  def run_db_validation? db_file
    !(TestConfig.skip_backups  && db_file =~ /(console_)?(split|full)_(local|nfs|smb)_backup\.tar\.gz/) &&
      !(TestConfig.skip_dumps  && db_file =~ /(console_)?(split|full)_(local|nfs|smb)_dump\.tar\.gz/)   &&
      !(TestConfig.skip_splits && db_file =~ /(console_)?split_(local|nfs|smb)_(dump|backup)\.tar\.gz/) &&
      (TestConfig.include_s3    || !(db_file =~ /(console_)?(split|full)_s3_(dump|backup)\.tar\.gz/))
      (TestConfig.include_swift || !(db_file =~ /(console_)?(split|full)_swift_(dump|backup)\.tar\.gz/))
  end
end
