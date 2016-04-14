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

        def _stored_options
          @_stored_options ||= {}
        end

        def add_stored_options(options)
          _stored_options.merge! options
        end

        def stored_option(name)
          name = name.to_sym
          raise "no such stored option #{name}" unless desc = _stored_options[name]
          method_option name, desc
        end
      end # ClassMethods
    end # OptionMod
  end # Cli
end # Buildizer
