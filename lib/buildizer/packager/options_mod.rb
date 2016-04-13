module Buildizer
  class Packager
    module OptionsMod
      attr_reader :options_path

      def options
        (@options ||= (YAML.load(options_path.read) rescue {})).tap do |res|
          @_options.each do |k, v|
            res[k.to_s] = v unless v.nil?
          end
        end
      end

      def option_set(key, value)
        @_options[key] = value
      end

      def options_setup!
        write_path(options_path, YAML.dump(options))
        @options = nil
      end

      module Initialize
        def initialize(options: {}, **kwargs)
          super(**kwargs)
          @_options = options
          @options_path = package_path.join('.buildizer.yml')
        end
      end # Initialize

      class << self
        def included(base)
          base.send(:prepend, Initialize)
        end
      end # << self
    end # OptionsMod
  end # Packager
end # Buildizer
