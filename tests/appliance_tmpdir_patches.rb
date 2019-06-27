# Require 'tmpdir' and override the result for `Dir.tmpdir` to be `/fake_tmp`
# for the duration of the ruby execution.
#
# To be used with `RUBYOPT` when running commands

require 'tmpdir'

# Doing this two ways for maximum coverage, since @systmpdir.dup is used if
# $SAFE > 0 and the ENV['TMPDIR'] has priority over @systmpdir if $SAFE = 0.
Dir.instance_variable_set(:@systmpdir, "/fake_tmp")
ENV['TMPDIR'] = "/fake_tmp"
