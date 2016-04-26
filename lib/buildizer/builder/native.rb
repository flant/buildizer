module Buildizer
  module Builder
    class Native < Base
      def build_type
        'native'
      end

      def target_klass
        Target::Native
      end

      def check_params!(params)
        super
        _required_params! :package_version, params
      end

      def build_instructions(target)
        target.os.native_build_instructions(target)
      end
    end # Native
  end # Builder
end # Buildizer
