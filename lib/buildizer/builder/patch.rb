module Buildizer
  module Builder
    class Patch < Base
      def build_type
        'patch'
      end

      def target_klass
        Target::Patch
      end

      def initial_target_params
        super.tap do |params|
          params[:patch] = Array(packager.buildizer_conf['patch'])
        end
      end

      def do_merge_params(into, params)
        super.tap do |res|
          res[:patch] = (into[:patch] + Array(params['patch'])).uniq
        end
      end

      def build_instructions(target)
        target.image.patch_build_instructions(self, target)
      end
    end # Patch
  end # Builder
end # Buildizer
