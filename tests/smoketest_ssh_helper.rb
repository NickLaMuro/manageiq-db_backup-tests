require 'net/ssh'
require 'net/scp'

class SSHHelper
  SHARE_HOST = "192.168.50.11".freeze
  SHARE_USER = "vagrant".freeze
  SHARE_KEY  = "/home/vagrant/.ssh/share.id_rsa".freeze
  CONFIG     = {
    :verify_host_key       => false,
    :user_known_hosts_file => File::NULL,
    :keys                  => [SHARE_KEY]
  }

  LS_COMMAND = "cd %s && ls -le %s 2> /dev/null"
  LS_PARSER  = Regexp.new <<-'REGEXP', Regexp::EXTENDED
    ^
    (?<FILE_PERMISSIONS>[d\-][rw\-]{9})\s+
    (?<NUM_LINKS>\d+)\s+
    (?<OWNER_NAME>\w+)\s+
    (?<OWNER_GROUP>\w+)\s+
    (?<FILE_SIZE>\d+)\s+
    # WKDAY MON DAY TIMESTAMP YEAR  =>  Mon Jan  1 00:00:00 2000
    (?<MOD_TIME>\w{3}\s\w{3}\s+\d+\s\d\d:\d\d:\d\d\s\d{4})\s+
    (?<FILE_NAME>.*)
    $
  REGEXP

  FileStat = Struct.new(:name, :size) do
    def <=> other
      self.name <=> other.name
    end
  end

  def self.stat filename
    get_file_list(filename).first
  end

  def self.file_exist? filename
    !get_file_list(filename).empty?
  end

  SSH_CMD_FAIL_MSG = "the following ssh cmd failed:\n\n  `%s`\n\n%s"
  def self.run_commands *cmds
    with_session do |ssh|
      cmds.each do |cmd|
        result = ssh.exec! cmd
        fail SSH_CMD_FAIL_MSG % [cmd, result] if result.exitstatus != 0
      end
    end
  end

  def self.get_file_list glob
    with_session do |ssh|
      dir    = File.dirname glob
      lsglob = File.basename glob
      lsglob = "#{lsglob}*"        if lsglob[-1] == "*"

      cmd    = LS_COMMAND % [dir, lsglob]
      result = ssh.exec! cmd

      if result.exitstatus == 0
        result.chomp.each_line.map do |line|
          match = line.match(LS_PARSER)
          FileStat.new match[:FILE_NAME], match[:FILE_SIZE].to_i
        end
      else
        []
      end
    end
  end

  def self.with_session &block
    Net::SSH.start(SHARE_HOST, SHARE_USER, CONFIG.dup) do |ssh|
      yield ssh
    end
  end
end
