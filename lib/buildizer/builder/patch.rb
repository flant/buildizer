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
          params[:patch] = Array(buildizer.buildizer_conf['patch'])
          params[:patch_version] = buildizer.buildizer_conf['patch_version']
        end
      end

      def do_merge_params(into, params)
        super.tap do |res|
          res[:patch] = (into[:patch] + Array(params['patch'])).uniq
          res[:patch_version] = into[:patch_version] || params['patch_version']
        end
      end

      def check_params!(params)
        super
        _required_params! :patch_version, params
      end

      def build_instructions(target)
        target.image.patch_build_instructions(self, target)
      end

      def build_dep(target)
        target.image.patch_build_dep(self, target)
      end
    end # Patch
  end # Builder
end # Buildizer
