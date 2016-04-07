module Buildizer
  module Target
    class Patch < Base
      attr_reader :patch
      attr_reader :patch_version

      def initialize(builder, image, patch: [], patch_version: nil, **kwargs, &blk)
        super(builder, image, **kwargs) do
          @patch = patch
          @patch_version = patch_version

          yield if block_given?
        end
      end

      def patch_version
        @patch_version.nil? ? nil : @patch_version.to_s
      end

      def image_work_path
        builder.work_path.join('patch').join(package_name).join(patch_version).join(name)
      end

      def container_package_name
        "#{package_name}-#{patch_version}"
      end

      def package_version_tag_param_name
        :patch_version
      end
    end # Patch
  end # Target
end # Buildizer
