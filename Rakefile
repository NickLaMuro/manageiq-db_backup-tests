VMS             = %w[appliance share]
VMDB_DIR        = "/var/www/miq/vmdb"
VAGRANT_SSH_CMD = 'vagrant ssh %s -c "%s"'

def vm_running? vmname
  state = read_vm_state vmname
  state == :running
end

VMSTATE_CMD_TEMPLATE = "VBoxManage showvminfo "                                \
                         "$(VBoxManage list vms | grep %s | cut -d ' ' -f 2) " \
                         "--machinereadable"

# ripped from vagrant virtualbox driver read_state
def read_vm_state vmname
  full_name = "appliance_smoketest_db_rake_tasks_#{vmname}"
  cmd       = VMSTATE_CMD_TEMPLATE % [full_name]
  output    = `#{cmd}`

  if output =~ /^name="<inaccessible>"$/
    return :inaccessible
  elsif output =~ /^VMState="(.+?)"$/
    return $1.to_sym
  end

  nil
end

desc "Setup"
task :setup => [".env", :seed]

desc "Seed the appliance DB"
task :seed => :start do
  bin_rails   = "#{VMDB_DIR}/bin/rails"
  seed_script = "#{VMDB_DIR}/tmp/bz_1592480_db_replication_script.rb"
  ssh_cmd     = "sudo -i #{bin_rails} r #{seed_script}"

  sh VAGRANT_SSH_CMD % [ "appliance", ssh_cmd ]
end

desc "Start the boxes"
task :start do
  vms_to_start = VMS.reject { |vmname| vm_running? vmname }

  if vms_to_start.empty?
    puts "vms already running..."
  else
    start_cmd  = "vagrant up"
    start_cmd << " #{vms_to_start.first}" if vms_to_start.size == 1

    # Must run through rake since it is a prereq for other tasks
    sh start_cmd
  end
end

desc "Stop the boxes"
task :stop do
  vms_to_stop = VMS.select { |vmname| vm_running? vmname }

  if vms_to_stop.empty?
    puts "vms already stopped..."
  else
    exec "vagrant halt"
  end
end
task :halt => :stop


desc "Destroy the boxes"
task :destroy do
  exec "vagrant destroy --force"
end

desc "Rebuild all boxes"
task :reset do
  exec "vagrant destroy --force && vagrant up"
end

namespace :reset do
  desc "Rebuild the appliance box"
  task :appliance do
    exec "vagrant destroy appliance --force && vagrant up appliance"
  end

  desc "Rebuild the share box"
  task :share do
    exec "vagrant destroy share --force && vagrant up share"
  end
end

desc "Run the tests"
task :test => [:setup, "test:test_args"] do
  test_cmd  = "sudo -i ruby /vagrant/tests/smoketest.rb "
  test_cmd << @test_args.join(" ")
  sh VAGRANT_SSH_CMD % [ "appliance", test_cmd ]
end

namespace :test do
  # Setup the @test_args var
  task :test_args do
    # @test_args = ["--restore-from-orig"]
    @test_args = ["--clean"]
  end

  desc "Skip S3 specs (run prior to `rake test`)"
  task :no_s3 => :test_args do
    @test_args << "--no-s3"
  end

  desc "Skip Swift specs (run prior to `rake test`)"
  task :no_swift => :test_args do
    @test_args << "--no-swift"
  end

  desc "Skip cleaning process (run prior to `rake test`)"
  task :no_clean => :test_args do
    @test_args.reject { |arg| arg == "--clean" }
  end
end

file ".env" do |file|
  require 'io/console'

  puts "Setting up .env file..."
  puts "-----------------------"
  puts
  puts "Note: 'required' vars are necessary for the specific provider to work."
  puts "If you don't have those particular variables available, make sure to"
  puts "skip those tests when running the test suite."
  puts

  defaults = <<-DOT_ENV.gsub(/^\s*/, '')
    AWS_REGION="us-east-1"
    AWS_ACCESS_KEY_ID="CHANGEME"
    AWS_SECRET_ACCESS_KEY="CHANGEME"
    SWIFT_HOST="REQUIRED"
    SWIFT_TENANT="admin"
    SWIFT_USERNAME="admin"
    SWIFT_PASSWORD="CHANGEME"
    SWIFT_REGION=""
    SWIFT_SECURITY_PROTOCOL="non-ssl"
    SWIFT_API_VERSION="v3"
    SWIFT_DOMAIN_ID="default"
  DOT_ENV

  File.open file.name, "w" do |io|
    defaults.lines.each do |line|
      name, default = line.split "="
      not_hidden    = default.tap(&:chomp!) != '"CHANGEME"'
      has_default   = !%w["REQUIRED" ""].include?(default)

      prompt  = "Enter value for #{name}"
      prompt << " (default: #{default})" if has_default && not_hidden
      prompt << " (required)"            if default == '"REQUIRED"'
      prompt << ": "

      print prompt

      input = if not_hidden
                STDIN.gets.chomp
              else
                STDIN.cooked { |io| io.noecho(&:gets) }.chomp.tap { puts }
              end

      value = input.size > 0 ? input : default.tr('"', '')

      io.puts "#{name}=#{value.inspect}"
    end
  end
end
