module Buildizer
  module Target
    class Patch < Base
      def initialize(builder, os, patch: [], patch_version: nil, **kwargs, &blk)
        super(builder, os, **kwargs) do
          params[:patch] = patch
          params[:patch_version] = patch_version

          yield if block_given?
        end
      end

      def patch_version
        params[:patch_version].nil? ? nil : params[:patch_version].to_s
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
