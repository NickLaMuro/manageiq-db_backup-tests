require 'etc'
require 'uri'
require 'fileutils'
require 'singleton'

require_relative "./smoketest_validator.rb"
require_relative "./smoketest_db_helper.rb"

class RakeHelper
  ACTION_MAP = {
    :backup       => [:backup,  {}],
    :backup_fktmp => [:backup,  { :fake_tmp => true }],
    :dump         => [:dump,    {}],
    :dump_fktmp   => [:dump,    { :fake_tmp => true }],
    :split_backup => [:backup,  { :split => true }],
    :split_dump   => [:dump,    { :split => true }],
    :restore      => [:restore, { :file_in_uri => true }]
  }

  include Singleton

  def self.test type, location, file
    action, opts = ACTION_MAP[type]
    verbose      = opts[:verbose]
    debug        = opts[:debug]
    test_case    = RakeTestCase.new file, action, location, opts

    if verbose || debug
      puts
      puts
      puts type.inspect
      puts location.inspect
      puts file.inspect
      puts opts.inspect
      puts test_case.send(:build_command)
      puts
      test_case.run_test if verbose
    else
      test_case.run_test
    end
  end

  def self.run_rake type, location, file, rake_args
    action, opts = ACTION_MAP[type]
    opts[:args]  = rake_args
    verbose      = opts[:args][:verbose]
    debug        = opts[:args][:debug]
    rake_runner  = RakeRunner.new file, action, location, opts

    if verbose || debug
      puts
      puts
      puts type.inspect
      puts location.inspect
      puts file.inspect
      puts rake_args.inspect
      puts rake_runner.send(:build_command)
      puts
      rake_runner.run_command if verbose
    else
      rake_runner.run_command
    end
  end

  def self.validate_databases *db_backups
    ::DbTestCase.validate *db_backups
  end

  def self.backup_sizes
    instance.backup_sizes
  end

  attr_reader :backup_sizes

  def initialize
    @backup_sizes = {}
  end

end

class RakeRunner
  DEFAULT_AUTH    = %w[vagrant vagrant].freeze
  REDACTED_AUTH   = %w[******** ********].freeze

  CMD_FAILED_PROMPT = <<-MSG.gsub(/^    /, "").freeze
    Command Failed
    --------------

  MSG

  include TestHelper

  attr_reader :file, :action, :location, :opts, :rake_cmd_args, :verbose, :debug

  def initialize file, action, location, opts = {}
    @file          = file
    @action        = action
    @location      = location
    @opts          = opts
    @debug         = @opts.fetch(:args, {}).delete(:debug)
    @verbose       = @opts.fetch(:args, {}).delete(:verbose)
    @rake_cmd_args = @opts.fetch(:args, {}).delete(:rake_cmd_args) || {}

    @redacted    = false
  end

  def run_command
    out, status = [StringIO.new, nil]
    run_in_vmdb do
      out_data, pipe = IO.pipe
      Thread.new { IO.copy_stream out_data, out }
      system(wrapped_cmd, [:out, :err] => pipe)
      pipe.close
      status = $?
    end
    status.success? || fail(CMD_FAILED_PROMPT + out.string)
  end

  private

  def build_command
    "rake #{task_name} #{task_args}"
  end

  def wrapped_cmd
    "sudo /bin/sh -c 'source /etc/profile.d/evm.sh; bin/#{build_command}'"
  end

  def task_name
    @task_name ||= "evm:db:#{action}:#{location == :local ? :local : :remote}"
  end

  def task_args options = {}
    args = base_rake_cmd_args

    case location
    when :local then args += "--local-file #{file}"
    when :nfs   then args += nfs_args
    when :smb   then args += smb_args
    when :s3    then args += s3_args
    when :ftp   then args += ftp_args
    when :swift then args += swift_args
    end

    args += add_additional_args.to_s
    args
  end

  def nfs_args
    generic_remote_args :path => '/var/nfs', :no_auth => true
  end

  def smb_args
    generic_remote_args :path => '/share'
  end

  def s3_args
    params = {
      :host => S3Helper.suite_s3_bucket_name,
      :auth => @redacted ? REDACTED_AUTH : S3Helper.auth_creds
    }

    generic_remote_args params
  end

  def ftp_args
    if FTPHelper.is_anonymous? file
      generic_remote_args :path => '/uploads', :no_auth => true
    else
      generic_remote_args
    end
  end

  def swift_args
    params = {
      :host => SwiftHelper.suite_host_name_and_port,
      :path => SwiftHelper.suite_container_path_and_options,
      :auth => @redacted ? REDACTED_AUTH : SwiftHelper.auth_creds
    }

    generic_remote_args params
  end

  def generic_remote_args params = {}
    path       = params[:path] || ''
    host       = params[:host] || SHARE_IP
    user, pass = params[:auth] || DEFAULT_AUTH
    uri        = URI::Generic.new *URI.split("#{location}://#{host}#{path}")
    uri.path  << "/#{file}"                if root_file_in_uri?
    uri.path  << "/#{namespaced_file}"     if namespaced_file_in_uri?

    args  = %Q{--uri "#{uri}"}
    args << " --uri-username #{user}"      unless params[:no_auth]
    args << " --uri-password #{pass}"      unless params[:no_auth]
    args << " --remote-file-name #{file}"  unless opts[:file_in_uri]
    args
  end

  def base_rake_cmd_args
    result  = args_hash_to_cmdline_string rake_cmd_args
    result << " --trace" if verbose
    result << " -- "
    result
  end

  def add_additional_args
    args_hash_to_cmdline_string @opts[:args] if @opts[:args]
  end

  def args_hash_to_cmdline_string args_hash
    args_hash.map do |key, value|
      if value.kind_of? Array
        value.map { |v| "--#{key.to_s.tr('_', '-')} #{v}" }.join(" ")
      else
        "--#{key.to_s.tr('_', '-')} #{value}"
      end
    end.unshift(nil).join(" ")
  end

  def namespaced_file
    return @namespaced_file if @namespaced_file
    @namespaced_file = if location == :local
                         file
                       else
                         _, type, _ = parse_db_filename file
                         folder = type == "backup" ? "db_backup" : "db_dump"
                         File.join(folder, file)
                       end
  end

  def root_file_in_uri?
    opts[:file_in_uri] && (!TestConfig.restore_from_original_dir && [:nfs, :smb].include?(location))
  end

  def namespaced_file_in_uri?
    opts[:file_in_uri] && (TestConfig.restore_from_original_dir || ![:nfs, :smb].include?(location))
  end
end

class RakeTestCase < RakeRunner
  SPLIT_SIZE          = 2 * MEGABYTES
  RAKE_TMPDIR_PATCHES = "/vagrant/tests/appliance_tmpdir_patches.rb"

  include MountHelper
  include Assertions

  def initialize *args
    super

    if @opts.delete(:fake_tmp) { false }
      @rake_cmd_args[:require] ||= nil
      @rake_cmd_args[:require]   = Array(@rake_cmd_args[:require])
      @rake_cmd_args[:require]  << RAKE_TMPDIR_PATCHES
    end
  end

  def split?
    @opts[:split]
  end

  def print_command
    @redacted = true
    build_command
  ensure
    @redacted = false
  end

  def run_test
    testing print_command do
      run_command
      check_sizes
    end
  end

  def check_sizes
    run_in_mount location do
      mount_file = File.join(*[@mount_point, namespaced_file].compact)
      if split?
        original_size = reference_db_size
        assert_split_files mount_file, SPLIT_SIZE, reference_db_size, error_margin
      else
        assert_file_exists mount_file
        save_db_size mount_file
      end
    end

    download_for_validation
  end

  private

  def task_args
    args  = super
    args += " -b 2M" if split?
    args
  end

  def reference_db_size
    reference_filename = file.sub /split/, 'full'
    RakeHelper.backup_sizes[reference_filename]
  end

  def save_db_size filepath
    RakeHelper.backup_sizes[file] = get_file_size filepath
  end

  def error_margin
    margin_of_error_for action, location
  end

  def download_for_validation
    case location
    # Move generated files on nfs/smb mounts to root to allow restore to
    # work, since it currently can't work with nested directories on mounts.
    when :nfs, :smb then
      run_in_mount(location) do |mnt|
        source = File.join mnt, "#{namespaced_file}*"
        FileUtils.cp_r Dir[source], mnt
      end unless TestConfig.restore_from_original_dir
    # Download DB to NFS share for validation
    when :s3 then
      run_in_mount(:nfs) { |mnt| S3Helper.download_to mnt, namespaced_file }
    when :swift then
      run_in_mount(:nfs) { |mnt| SwiftHelper.download_to mnt, namespaced_file }
    end
  end
end
