module Buildizer
  module Os
    class Base
      attr_reader :docker

      def initialize(docker, **kwargs)
        @docker = docker
      end

      def base_image_name
        "buildizer/#{base_vendor_image_name}"
      end

      def base_vendor_image_name
        "#{os_name}:#{os_version}"
      end

      def os_name # FIXME: name, version, codename
        raise
      end

      def os_package_cloud_name
        os_name
      end

      def os_package_cloud_version
        os_version
      end

      def os_version
        raise
      end

      def fpm_output_type
        raise
      end

      def fpm_extra_params
      end

      def build_dep(image, build_dep)
        raise
      end

      def patch_build_dep(target)
        target_package_spec(target)
      end

      def native_build_instructions(target)
        raise
      end

      def patch_build_instructions(target)
        raise
      end

      def target_package_spec(target)
        raise
      end
    end # Base
  end # Os
end # Buildizer