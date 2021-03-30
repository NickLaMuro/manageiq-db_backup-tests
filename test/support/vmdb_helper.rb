module VmdbHelper
  MIQ_ROOT = File.join "", *%w[var www miq vmdb]

  module_function

  def run_in_vmdb
    Dir.chdir("/var/www/miq/vmdb") { |dir| yield dir }
  end
end
