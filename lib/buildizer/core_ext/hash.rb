class Hash
  def zymbolize_keys
    map do |key, value|
      [_zymbolize(key), value]
    end.to_h
  end

  def zymbolize_keys!
    keys.each do |key|
      self[_zymbolize(key)] = delete(key)
    end
    self
  end

  def zymbolize_keys_deep
    map do |key, value|
      [_zymbolize(key), if value.is_a? Hash
        value.zymbolize_keys_deep
      else
        value
      end]
    end.to_h
  end

  def zymbolize_keys_deep!
    queue = [self]
    visited = Set.new
    while hash = queue.shift
      visited.add hash
      hash.keys.each do |key|
        value = hash.delete(key)
        hash[_zymbolize(key)] = value
        queue << value if value.is_a? Hash and not visited.include? hash
      end
    end
    self
  end

  def net_status_message
    [self[:error], self[:message]].compact.join(': ')
  end

  private

  def _zymbolize(value)
    value.respond_to?(:to_sym) ? value.to_sym : value
  end
end # Hash
