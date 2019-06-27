module TestHelper
  def testing desc
    if TestConfig.run_test? desc
      print "Testing \e[1m#{desc}\e[0m... "
      yield
      puts "\e[32m✓\e[0m"
    end
  rescue RuntimeError => e
    puts "\e[31mx\e[0m"
    TestErrors.add desc, e
  end

  def run_in_vmdb
    Dir.chdir("/var/www/miq/vmdb") { yield }
  end

  def parse_db_filename filename
    parts    = filename.split("_") - ["console"]
    split    = parts.first == "split"
    location = parts[1].to_sym
    type     = parts.last.split(".").first
    console  = filename.start_with?("console")

    [location, type, console, split]
  end
end

module MountHelper
  MOUNT_TYPE_STRINGS = {
    :nfs => "sudo mount -t nfs '192.168.50.11:/var/nfs' %s",
    :smb => "sudo mount -t cifs '//192.168.50.11/share' %s -o rw,username=vagrant,password=vagrant"
  }
  def run_in_mount mount_type
    if mount_cmd = MOUNT_TYPE_STRINGS[mount_type]
      @mount_point = Dir.mktmpdir "miq_"
      system mount_cmd % @mount_point
    end

    yield @mount_point

  ensure
    if @mount_point && Dir.exist?(@mount_point)
      system "sudo umount #{@mount_point}"
      Dir.rmdir @mount_point
    end
    @mount_point = nil
  end
end

module Assertions
  def assert_file_exists filename
    if filename =~ /_s3_/
      S3Helper.file_exist? filename
    elsif filename =~ /_ftp_/
      file = File.basename filename
      FTPHelper.file_exist? file
    elsif filename =~ /_swift_/
      SwiftHelper.file_exist? file
    else
      run_in_vmdb do
        File.exist? filename
      end
    end || fail("#{filename} not found!")
  end

  # With this, when testing a backup (versus a dump), since the postgres process
  # is still running, this can change the filesize (and usually does) within the
  # 5 seconds of running the "original" test and the "split" test.
  #
  # Usually isn't more than 80 bytes, but keeping a decent margin for error just
  # in case, and the output is pretty verbose when it fails.
  def assert_split_totals split_files, expected_total, margin
    actual_total = split_files.inject(0) { |sum, file| sum += file.size }
    actual_total == expected_total                                                || # totals are the same
      (actual_total > expected_total && (actual_total - expected_total) < margin) || # totals within 200 bytes
      fail_for_combined_total(split_files, expected_total)
  end

  def assert_correct_split_sizes file_list, split_amount
    return if file_list.all? { |file| file.size == split_amount }

    err_msg     = ["Split files have the wrong sizes!"]
    err_msg    += file_list.map { |file| "  #{file.name}: #{file.size} (expected #{split_amount})" }

    fail err_msg.join("\n")
  end

  def assert_split_files split_base_uri, split_amount, total_size, margin_of_error=0
    get_file_list(split_base_uri).tap do |file_list|
      file_list.count > 0 || fail("File list for #{split_base_uri}* is empty!")
      assert_split_totals file_list, total_size, margin_of_error
      assert_correct_split_sizes file_list.sort[0..-2], split_amount
    end
  end

  def margin_of_error_for action, location
    if action == :dump
      0
    elsif location == :s3 or location == :swift
      300
    else
      200
    end
  end

  def get_file_list(split_base_uri)
    if split_base_uri =~ /_s3_/
      S3Helper.get_file_list(split_base_uri)
    elsif split_base_uri =~ /_ftp_/
      FTPHelper.get_file_list("#{File.basename split_base_uri}.*")
    elsif split_base_uri =~ /_swift_/
      SwiftHelper.get_file_list(split_base_uri)
    else
      # Gets files for mounted dirs or one that have been saved locally.
      #
      # Either we save them to vmdb root, in which we are just using relative
      # paths, or this is for a mount, which we have already joined to get an absolute path in the tests.
      #
      # just how I have written them... #dealwithit
      #
      # Also, wrap these in `File` objects so we can `.size` them directly, and
      # calling out multiple times to `get_file_size` isn't necessary.  This is
      # assuming in the specs that all of the tests are going to re-download or
      # mount the files we are asking for, but since we need to do this for
      # validating the DBs anyway, this isn't a problem.
      run_in_vmdb do
        Dir["#{split_base_uri}.*"].map { |filename| File::Stat.new(filename) }
      end
    end
  end

  def get_file_size filename
    if filename =~ /_s3_/
      S3Helper.stat(filename).size
    elsif filename =~ /_ftp_/
      FTPHelper.stat(File.basename filename).size
    elsif filename =~ /_swift_/
      SwiftHelper.stat(filename).size
    else
      run_in_vmdb { File.stat(filename).size }
    end
  end

  def fail_for_combined_total file_list, expected_total
    err_msg     = ["Split files don't add up to original!"]
    err_msg    += file_list.map { |file| "  #{file.name}: #{file.size}" }
    err_msg    << "Expected Total:  #{expected_total}"
    err_msg    << "Actual Total:    #{file_list.map(&:size).reduce(0, :+)}"

    fail err_msg.join("\n")
  end
end
