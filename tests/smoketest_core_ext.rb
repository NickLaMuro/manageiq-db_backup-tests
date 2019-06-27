# HACK: "Enhance" File::Stat to keep track of the name we pass to it
File::Stat.prepend Module.new {
  def initialize(filename)
    @name = filename
    super
  end

  def name; @name; end
}
