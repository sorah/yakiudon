class File
  def self.safe_delete(path,*safe)
    safe.push(Yakiudon::Config.public,Yakiudon::Config.db) if safe.empty?

    if safe.any? {|s| File.expand_path(path).include?(File.expand_path(s)) }
      File.delete(path)
    else
      raise ArgumentError, "unsafe delete"
    end
  end
end
