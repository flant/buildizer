class String
  def underscore
    self.gsub(/(.)([A-Z])/,'\1_\2').downcase
  end

  def match_glob?(glob)
    File.fnmatch? glob, self, File::FNM_EXTGLOB
  end

  def on?
    ['1', 'true', 'yes'].include? self.downcase
  end

  def off?
    !on?
  end
end # String
