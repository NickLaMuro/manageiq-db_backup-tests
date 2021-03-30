module Assertions
  module CustomAttributes
    def assert_has_custom_attributes(backup_file)
      assert DbValidator.new(backup_file).has_custom_attributes?,
             "#{backup_file} was not a valid database (does not have custom attributes!)"
    end

    def refute_has_custom_attributes(backup_file)
      refute DbValidator.new(backup_file).has_custom_attributes?,
             "#{backup_file} was not a valid database (has custom attributes!)"
    end
  end
end
