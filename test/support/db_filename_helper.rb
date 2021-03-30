module DbFilenameHelper
  def parse_db_filename filename
    parts    = filename.split("_") - ["console"]
    split    = parts.first == "split"
    location = parts[1].to_sym
    type     = parts.last.split(".").first
    console  = filename.start_with?("console")

    [location, type, console, split]
  end
end

