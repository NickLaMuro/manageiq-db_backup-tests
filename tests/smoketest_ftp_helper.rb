require 'net/ftp'

require_relative "./smoketest_ssh_helper.rb"

class FTPHelper
  VAGRANT_CREDENTIALS   = ["vagrant", "vagrant"]
  ANONYMOUS_CREDENTIALS = []
  CREDENTIALS           = {
    true  => ANONYMOUS_CREDENTIALS,
    false => VAGRANT_CREDENTIALS
  }

  FileStat = Struct.new(:name, :size) do
    def <=> other
      self.name <=> other.name
    end
  end

  attr_accessor :ftp
  attr_reader   :anonymous

  def self.with_connection filename = false, &block
    if is_anonymous? filename
      SSHHelper.instance_exec &block
    else
      begin
        ftp = new filename
        ftp.instance_exec &block
      ensure
        ftp.close
      end
    end
  end

  def self.rake_opts filename, options = {}
    opts  = %w[--uri ftp://192.168.50.11]
    if options[:anonymous]
      opts.last << "/uploads"
    else
      opts << %w[--uri-username --uri-password].zip(VAGRANT_CREDENTIALS)
    end
    opts << "--remote-file-name".freeze
    opts << filename
    opts += %w[-b 2M] if options[:split]
    opts.join " "
  end

  def self.file_exist? filename
    filename = full_filepath filename if is_anonymous? filename
    with_connection(filename) { file_exist? filename }
  end

  def self.stat filename
    filename = full_filepath filename if is_anonymous? filename
    with_connection(filename) { stat filename }
  end

  def self.get_file_list glob
    glob = full_filepath glob if is_anonymous? glob
    with_connection(glob) { get_file_list glob }
  end

  def self.clear_user_directory
    with_connection { clear_user_directory }
  end

  def self.full_filepath filename
    File.join dirname_for(filename), filename
  end

  def self.dirname_for filename
    File.join base_dir_for(filename), db_dir_for(filename)
  end

  def self.db_dir_for filename
    filename =~ /dump/ ? "db_dump" : "db_backup"
  end

  def self.base_dir_for filename
    if is_anonymous? filename
      File.join "", *%w[var nfs ftp pub uploads]
    else
      File.join "", *%w[home vagrant]
    end
  end

  def self.is_anonymous? filename_or_bool
    if filename_or_bool.kind_of?(String)
      filename_or_bool =~ /anonymous/
    else
      filename_or_bool
    end
  end

  def initialize anonymous = false
    @anonymous = !!self.class.is_anonymous?(anonymous)
    connect
  end

  def connect
    @ftp = Net::FTP.new("192.168.50.11")
    @ftp.login(*CREDENTIALS[anonymous])
    @ftp
  end

  def file_exist? filename
    !get_file_list(filename).empty?
  end

  def stat filename
    FileStat.new(filename, ftp.size(self.class.full_filepath filename))
  rescue => e
    fail "oh the huge manatee"
  end

  def get_file_list glob
    ftp.chdir self.class.dirname_for(glob)
    ftp.nlst(glob).map { |file| stat file }
  end

  def clear_user_directory
    %w[db_dump db_backup].each do |dir|
      next if ftp.nlst(dir).empty?
      ftp.chdir dir
      ftp.nlst("*").each { |file| ftp.delete(file) }
      ftp.chdir ".."
      ftp.rmdir dir
    end
  end

  def close
    ftp.close
  end
end
