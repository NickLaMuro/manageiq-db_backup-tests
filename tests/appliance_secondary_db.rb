require "etc"
require "fileutils"

class ApplianceSecondaryDB
  extend FileUtils

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
    cmd = %Q{su vagrant -lc \"#{cmd}\"} if Etc.getlogin == "vagrant"
    system cmd, [:out, :err] => File::NULL
  end

  def self.rebuild_data_dir
    rm_rf   Dir["#{DATA_DIR}/*"]
    mkdir_p DATA_DIR
    mkdir_p RUN_DIR
    chown_R "vagrant", "vagrant", DATA_DIR
    chown_R "vagrant", "vagrant", RUN_DIR

    run_cmd "pg_ctl initdb -D #{DATA_DIR} -o '-A trust'"
  end

  def self.create_roles
    run_cmd %Q{psql --port 5555 -h localhost -c \\"CREATE ROLE root WITH LOGIN CREATEDB SUPERUSER PASSWORD 'smartvm'\\" postgres}
    run_cmd %Q{psql --port 5555 -h localhost -c \\"CREATE ROLE postgres\\" postgres}
  end

  def self.update_config
    conf_file = File.join DATA_DIR, 'postgresql.conf'
    conf      = File.read conf_file
    conf.gsub! "include_dir = '/etc/manageiq/postgresql.conf.d'", "ssl = on"
    conf     << "\n\nunix_socket_directories = '#{RUN_DIR}, /tmp'"

    File.write conf_file, conf
  end
end
