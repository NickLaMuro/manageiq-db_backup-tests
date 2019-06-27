class DotEnvFile
  DOT_ENV_LINE_MATCH = /^(?<ENV_VAR>[A-Z_]+)\s*=\s*("|')?(?<ENV_VAL>[^"']*)?("|')?$/
  def self.parse
    File.open(File.join(File.dirname(__FILE__), ".env")) do |env_file|
      env_file.each_line do |line|
        next unless match = line.strip.match(DOT_ENV_LINE_MATCH)

        ENV[match[:ENV_VAR]] = match[:ENV_VAL]
      end
    end
  end
end

# load in env vars
DotEnvFile.parse
