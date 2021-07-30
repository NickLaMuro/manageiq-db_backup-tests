require 'etc'
require 'uri'
require 'fileutils'
require 'singleton'

require_relative './vmdb_helper.rb'
require_relative './db_filename_helper.rb'

class ApplianceConsoleCli
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
  include DbFilenameHelper

  ##
  # Run a test case for the appliance_console_cli
  #
  # ==== Parameters
  #
  # [*type* (Symbol)]      Command run (:backup, :dump, :restore, etc.)
  # [*location* (Symbol)]  Location of backup (:local, :nfs, :smb, etc.)
  # [*file* (String)]      File path location of backup
  #
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


  ##
  # Run a command for using the appliance_console_cli without any test
  # expectations involved.
  #
  # Generally this will be called by DbValidator, and not called directly
  #
  # ==== Parameters
  #
  # [*type* (Symbol)]      Command run (:backup, :dump, :restore, etc.)
  # [*location* (Symbol)]  Location of backup (:local, :nfs, :smb, etc.)
  # [*file* (String)]      File path location of backup
  # [*args* (Hash)]        Extra arguments to pass to the command
  #
  def self.run_cmd type, location, file, cli_args
    action, opts = ACTION_MAP[type]
    opts[:args]  = cli_args
    verbose      = opts[:args][:verbose]
    debug        = opts[:args][:debug]
    rake_runner  = Runner.new file, action, location, opts

    if verbose || debug
      puts
      puts
      puts type.inspect
      puts location.inspect
      puts file.inspect
      puts cli_args.inspect
      puts rake_runner.send(:build_command)
      puts
      rake_runner.run_command if verbose
    else
      rake_runner.run_command
    end
  end

  class Runner
    DEFAULT_AUTH    = %w[vagrant vagrant].freeze
    REDACTED_AUTH   = %w[******** ********].freeze

    CMD_FAILED_PROMPT = <<-MSG.gsub(/^    /, "").freeze
      Command Failed
      --------------

    MSG

    include VmdbHelper
    include DbFilenameHelper

    attr_reader :debug, :file, :action, :location, :opts, :rubyopt, :verbose

    ##
    # Runs a single instance of an appliance_console_cli command.
    #
    # Don't use directly!  Call via ApplianceConsoleCli.run_cmd
    #
    def initialize file, action, location, opts = {}
      @file          = file
      @action        = action
      @location      = location
      @opts          = opts
      @debug         = @opts.fetch(:args, {}).delete(:debug) || ENV["TEST_DEBUG"]
      @verbose       = @opts.fetch(:args, {}).delete(:verbose)
      @rubyopt       = @opts.fetch(:args, {}).delete(:rubyopt)

      @redacted    = false
    end

    def run_command
      out, status = [StringIO.new, nil]

      if debug
        puts "running appliance_console_cli..."
        puts "  $ #{wrapped_cmd}"
      end

      run_in_vmdb do
        out_data, pipe = IO.pipe
        Thread.new { IO.copy_stream out_data, out }
        system(wrapped_cmd, [:out, :err] => pipe)
        pipe.close
        status = $?
      end
      status.success? || fail("#{CMD_FAILED_PROMPT}$ #{wrapped_cmd}\n\n#{out.string}")
    end

    private

    def build_command
      "#{build_rubyopt} appliance_console_cli #{task_name} #{task_args}"
    end

    def build_rubyopt
      %Q'RUBYOPT="#{rubyopt}"' if rubyopt
    end

    def wrapped_cmd
      "sudo /bin/sh -c 'source /etc/profile.d/evm.sh; #{build_command}'"
    end

    def task_name
      @task_name ||= "--#{action}"
    end

    def task_args options = {}
      args  = "--local-file #{file} "
      args += add_additional_args
      args
    end

    def generic_remote_args params = {}
      path       = params[:path] || ''
      host       = params[:host] || ::SHARE_IP
      uri        = URI::Generic.new(*URI.split("#{location}://#{host}#{path}"))
      uri.path  << "/#{file}"                if root_file_in_uri?
      uri.path  << "/#{namespaced_file}"     if namespaced_file_in_uri?

      args  = %Q{--uri "#{uri}"}
      args
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
      end.unshift(nil).join(" ").to_s
    end

    def namespaced_file
      return @namespaced_file if defined?(@namespaced_file)
      @namespaced_file = if location == :local
                           file
                         else
                           basename    = File.basename file
                           _, type, __ = parse_db_filename basename
                           folder      = type == "backup" ? "db_backup" : "db_dump"

                           File.join(folder, basename)
                         end
    end

    def root_file_in_uri?
      opts[:file_in_uri] && false && [:nfs, :smb].include?(location)
    end

    def namespaced_file_in_uri?
      opts[:file_in_uri] && [:nfs, :smb].include?(location)
    end
  end
end
