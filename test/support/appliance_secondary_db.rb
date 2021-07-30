require "fileutils"

class ApplianceSecondaryDB
  extend FileUtils

  DB_USER  = "vagrant"
  PG_DIR   = File.join("", "opt", "manageiq", "postgres_restore_pg").freeze
  RUN_DIR  = File.join(PG_DIR, "run").freeze
  DATA_DIR = File.join(PG_DIR, "data").freeze

  def self.start
    update_config
    run_cmd "pg_ctl start -D  #{DATA_DIR} -wo '-p 5555'"
  end

  def self.stop
    run_cmd "pg_ctl stop -D #{DATA_DIR} -wm fast"
  end

  def self.reset_db
    stop
    rebuild_data_dir
    start
    create_roles
  end

  def self.run_cmd cmd
    cmd         = %Q{sudo -u #{DB_USER} #{cmd}}
    cmd_options = ENV["TEST_DEBUG"] ? {} : {[:out, :err] => File::NULL}

    puts "$ #{cmd}" if ENV["TEST_DEBUG"]

    system cmd, cmd_options
  end

  def self.rebuild_data_dir
    rm_rf   DATA_DIR, verbose: !!ENV["TEST_DEBUG"]
    mkdir_p DATA_DIR, verbose: !!ENV["TEST_DEBUG"]
    mkdir_p RUN_DIR, verbose: !!ENV["TEST_DEBUG"]
    chown_R DB_USER, DB_USER, DATA_DIR, verbose: !!ENV["TEST_DEBUG"]
    puts `ls -lh #{DATA_DIR}` if ENV["TEST_DEBUG"]
    chown_R DB_USER, DB_USER, RUN_DIR, verbose: !!ENV["TEST_DEBUG"]
    puts `ls -lh #{DATA_DIR}` if ENV["TEST_DEBUG"]

    run_cmd "pg_ctl initdb -D #{DATA_DIR} -o '-A trust'"
    chown_R DB_USER, DB_USER, DATA_DIR, verbose: !!ENV["TEST_DEBUG"]
    puts `ls -lh #{DATA_DIR}` if ENV["TEST_DEBUG"]
    chown_R DB_USER, DB_USER, RUN_DIR, verbose: !!ENV["TEST_DEBUG"]
    puts `ls -lh #{DATA_DIR}` if ENV["TEST_DEBUG"]
  end

  def self.create_roles
    run_cmd %Q{psql --port 5555 -h /opt/manageiq/postgres_restore_pg/run -c "CREATE ROLE root WITH LOGIN CREATEDB SUPERUSER PASSWORD 'smartvm'" postgres}
    run_cmd %Q{psql --port 5555 -h /opt/manageiq/postgres_restore_pg/run -c "CREATE ROLE postgres" postgres}
  end

  def self.update_config
    conf_file = File.join DATA_DIR, 'postgresql.conf'
    conf      = File.read conf_file
    conf.gsub! "include_dir = '/etc/manageiq/postgresql.conf.d'", "ssl = on"
    conf     << "\n\nunix_socket_directories = '#{RUN_DIR}'"

    File.write conf_file, conf
  end
end
