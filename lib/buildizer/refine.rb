module Buildizer
  module Refine
    refine String do
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

    refine Pathname do
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

    refine TrueClass do
      def to_env
        'yes'
      end
    end # TrueClass

    refine FalseClass do
      def to_env
        'no'
      end
    end # FalseClass
  end # Refine
end # Buildizer
