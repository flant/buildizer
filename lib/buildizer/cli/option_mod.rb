module Buildizer
  module Cli
    module OptionMod
      class << self
        def included(base)
          base.send(:extend, ClassMethods)
        end
      end # << self

      module ClassMethods
        def _shared_options
          @_shared_options ||= {}
        end

        def _all_shared_options
          res = _shared_options
          if klass = self.superclass and klass.respond_to?(:_all_shared_options)
            res = res.merge(klass._all_shared_options)
          end
          res
        end

        def add_shared_options(options)
          _shared_options.merge! options
        end

        def shared_options
          _all_shared_options.each do |name, options|
            method_option name, options
          end
        end
      end # ClassMethods
    end # OptionMod
  end # Cli
end # Buildizer
