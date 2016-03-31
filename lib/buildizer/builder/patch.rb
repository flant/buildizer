module Buildizer
  module Builder
    class Patch < Base
      def build_type
        'patch'
      end

      def target_klass
        Target::Patch
      end

      def build_instructions(target)
      end
    end # Patch
  end # Builder
end # Buildizer
