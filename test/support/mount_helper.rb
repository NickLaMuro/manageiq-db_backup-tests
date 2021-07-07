require 'tmpdir'

module MountHelper
  MOUNT_TYPE_STRINGS = {
    :nfs => "sudo mount -t nfs '192.168.50.11:/var/nfs' %s",
    :smb => "sudo mount -t cifs '//192.168.50.11/share' %s -o rw,username=vagrant,password=vagrant"
  }

  module_function

  def run_in_mount mount_type
    if mount_cmd = MOUNT_TYPE_STRINGS[mount_type]
      @mount_point = Dir.mktmpdir "miq_"
      puts "$ #{mount_cmd % @mount_point}" if ENV["TEST_DEBUG"]
      system mount_cmd % @mount_point
    end

    Dir.chdir(@mount_point) { |dir| yield dir }

  ensure
    if @mount_point && Dir.exist?(@mount_point)
      system "sudo umount #{@mount_point}"
      Dir.rmdir @mount_point
    end
    @mount_point = nil
  end
end
