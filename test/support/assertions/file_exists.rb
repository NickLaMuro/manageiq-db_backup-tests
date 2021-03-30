module Assertions
  module FileExists
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
          message = "Expected path #{filename} to exist"

          if ApplianceConsoleRunner.current
            message += "\n\n>>>>> IO Log <<<<<\n\n"
            message += ApplianceConsoleRunner.current.io_log.tap(&:rewind).read
          end

          assert filename, message
        end
      end
    end
  end
end
