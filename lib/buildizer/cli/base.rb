module Buildizer
  module Cli
    class Base < ::Thor
      include OptionMod

      add_shared_options(
        debug: {type: :boolean, default: false, desc: "turn on live logging for external commands"},
      )

      class << self
        def construct_packager(options)
          opts = options.select do |k, v|
            _stored_options.key? k.to_sym
          end
          Buildizer::Packager.new(options: opts, debug: options['debug'])
        end
      end # << self
    end # Base
  end # Cli
end # Buildizer
