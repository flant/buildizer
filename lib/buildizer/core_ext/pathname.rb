class Pathname
  def load_yaml
    exist? ? YAML.load(read) : {}
  rescue Psych::Exception => err
    raise Buildizer::Error, error: :input_error,
                            message: "bad yaml config file #{self}: #{err.message}"
  end

  def dump_yaml(cfg)
    write! YAML.dump(cfg)
  end

  def write!(*args, &blk)
    dirname.mkpath
    write(*args, &blk)
  end
end # Pathname
