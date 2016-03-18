module Buildizer
  module Builder
    class Native < Base
      def build_type
        'native'
      end

      def target_klass
        Target::Native
      end

      def initial_target_params
        super.tap do |params|
          params[:package_version] = packager.package_version_tag
        end
      end

      def build_instructions(target)
        target.image.native_build_instructions(self, target)
      end
    end # Native
  end # Builder
end # Buildizer
