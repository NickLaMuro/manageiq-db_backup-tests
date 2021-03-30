require 'stringio'
require 'pty'

class ApplianceConsoleRunner
  class Current
    class << self
      attr_accessor :instance
    end
  end

  def self.current
    Current.instance
  end

  attr_reader :state, :type, :file, :io_log, :mode, :split, :finished

  CLEAR_CODE  = `clear`
  SMB_CREDS   = ["vagrant", "vagrant"].freeze
  FTP_CREDS   = SMB_CREDS
  FTP_ANON    = ["", ""].freeze
  CONSOLE_CMD = "/opt/manageiq/manageiq-gemset/bin/appliance_console".freeze

  STATE_OUTPUT_LINES = {
    "Advanced Setting"               => :main_menu,
    "Backup Output File Destination" => :io_menu,
    "Create Database Dump"           => :io_menu,
    "Create Database Backup"         => :io_menu
  }.freeze

  PRESS_ANY_KEY_REGEXP = /^Press any key to continue.*$/.freeze
  MAIN_MENU_OPTION_REGEXPS = {
    :backup  => /^(?<OPTION_NUMBER>\d*)\).*Database Backup.*$/,
    :dump    => /^(?<OPTION_NUMBER>\d*)\).*Database Dump.*$/,
    :restore => /^(?<OPTION_NUMBER>\d*)\).*Restore Database.*$/,
    :quit    => /^(?<OPTION_NUMBER>\d*)\).*Quit.*$/
  }.freeze

  def self.backup file, mode = :local, split = nil
    new(:backup, file, mode, split).run_console
  end

  def self.dump file, mode = :local, split = nil
    new(:dump, file, mode, split).run_console
  end

  def self.dump_with_no_custom_attributes file, mode = :local, split = nil
    new(:dump, file, mode, split, ['custom_attributes']).run_console
  end

  def initialize type, file, mode, split, table_exclusions=[]
    @state            = nil
    @input            = []
    @type             = type
    @io_log           = StringIO.new
    @mode             = mode
    @file             = localize file
    @split            = split
    @table_exclusions = table_exclusions
    @finished         = false

    Current.instance  = self
  end

  def run_console
    status = nil

    PTY.spawn CONSOLE_CMD do |out, stdin, pid|
      cmd_tr = Process.detach(pid)

      # Output parser thread
      output = Thread.new do
        begin
          while line = out.gets
            debug "(output thread) #{line.inspect}"
            new_input = line_parser line
            @input += Array(new_input) if new_input
          end
        rescue Errno::EIO
        end
      end

      # Input thread
      input  = Thread.new do
        while cmd_tr.alive?
          if @input.empty?
            sleep 0.5
          else
            sleep 1 # give the sub process a second to accept input
            input_line = @input.shift
            debug "(input thread) #{input_line.inspect}"
            stdin.puts input_line
          end
        end
      end

      # Timeout Thread
      Thread.new do
        waits_left = starting_wait
        while cmd_tr.alive? && waits_left > 0
          waits_left -= 1
          sleep 2
        end
        if cmd_tr.alive?
          eof_wait         = 0
          remaining_output = ""

          until out.eof? || eof_wait > 5
            extra_out = out.read_nonblock(1000)

            if extra_out != ""
              remaining_output << extra_out
            else
              eof_wait += 1
              sleep 2
            end
          end

          debug "----- (debug thread) -----"
          debug input.backtrace
          debug "--------------------------"
          debug output.backtrace
          debug "--------------------------"
          debug "@state:             #{@state.inspect}"
          debug "@input:             #{@input.inspect}"
          debug "@type:              #{@type.inspect}"
          debug "@mode:              #{@mode.inspect}"
          debug "@file:              #{@file.inspect}"
          debug "@split:             #{@split.inspect}"
          debug "@table_exclusions:  #{@table_exclusions.inspect}"
          debug "@finished:          #{@finished.inspect}"
          debug "--------------------------"
          debug "remaining output...."
          debug remaining_output.lines.map(&:inspect)
          debug "----- (debug thread) -----"
          Process.kill("KILL", cmd_tr.pid)
        end
      end

      status = cmd_tr.value # effectively thread.join
    end

    fail "appliance_console command timed out" if status.signaled? && status.termsig == 9
    fail "appliance_console ran into an error" unless status.success?
  end

  private

  def localize filename
    case mode
    when :local
      "/var/www/miq/vmdb/#{filename}"
    when :nfs
      @uri = "#{mode}://192.168.50.11:/var/#{mode}"
      filename
    when :smb
      @uri = "#{mode}://192.168.50.11:/share"
      filename
    when :s3
      @uri = "#{mode}://#{S3Helper.suite_s3_bucket_name}/"
      filename
    when :swift
      @uri = "#{mode}://#{SwiftHelper.suite_swift_bucket_name}/"
      filename
    when :ftp, :ftp_anonymous
      @uri  = "ftp://192.168.50.11"
      @uri += "/uploads" if mode == :ftp_anonymous
      debug "(internal) uri to be passed:  #{@uri.inspect}"
      filename
    end
  end

  def line_parser line
    if line =~ PRESS_ANY_KEY_REGEXP
      @state = nil
      return ""
    end

    case state
    when :main_menu
      menu_option = finished ? :quit : type
      match = line.match MAIN_MENU_OPTION_REGEXPS[menu_option]
      @state = nil if match
      match && match[:OPTION_NUMBER]
    when :io_menu
      @state = nil
      inject_input unless @finished
    else # state change check
      # Some of the menu prompts come right after a clear, and so `out.gets`
      # doesn't pick that up properly as a seperate line.  Split will return
      # the whole string anyway if there is no CLEAR_CODE, so doesn't hurt much
      # to have it in here.
      new_state = STATE_OUTPUT_LINES[line.split(CLEAR_CODE).last.strip]
      @state = new_state if new_state
      nil
    end
  end

  def inject_input
    @finished      = true
    exclude_tables = if @table_exclusions.empty?
                       ["n"]
                     else
                       ["y"] + @table_exclusions + [""]
                     end

    if [:smb, :nfs].include? mode
      inject = [file]
    else
      inject = [file]
    end

    # inject += SMB_CREDS      if mode == :smb
    # inject += aws_input      if mode == :s3
    # inject += FTP_CREDS      if mode == :ftp
    # inject += FTP_ANON       if mode == :ftp_anonymous
    # inject += swift_input    if mode == :swift
    inject += exclude_tables if type == :dump
    inject += ["n", "y"]     if type == :restore && mode == :local
                             # ^ don't delete backup (but answer)
    inject
  end

  def aws_input
    [
      ENV["AWS_REGION"],
      ENV["AWS_ACCESS_KEY_ID"],
      ENV["AWS_SECRET_ACCESS_KEY"]
    ]
  end

  def swift_input
    [
      SwiftHelper.auth_creds[0].to_s,
      SwiftHelper.auth_creds[1].to_s,
      SwiftHelper.region.to_s,
      SwiftHelper.port.to_s,
      SwiftHelper.security_protocol.to_s,
      SwiftHelper.api_version.to_s,
      (SwiftHelper.include_domain_id? ? SwiftHelper.domain_id : nil)
    ].compact
  end

  def starting_wait
    case mode
    when :s3, :ftp, :ftp_anonymous, :swift then 60
    else 20
    end
  end

  def io_key
    case mode
    when :ftp_anonymous then :ftp
    else mode
    end
  end

  def debug input
    @io_log.puts input
    puts input if false
  end
end
