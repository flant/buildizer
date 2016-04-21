class Pathname
  def load_yaml
    exist? ? YAML.load(read) : {}
  rescue Psych::Exception => err
    raise Error, error: :input_error,
                 message: "bad yaml config file #{self}: #{err.message}"
  end

  def write!(*args, &blk)
    dirname.mkpath
    write(*args, &blk)
  end
end # Pathname
