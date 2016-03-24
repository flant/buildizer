module Buildizer
  module Target
    class Base
      attr_reader :builder
      attr_reader :image

      attr_reader :name
      attr_reader :package_name
      attr_reader :package_version
      attr_reader :package_cloud
      attr_reader :prepare
      attr_reader :build_dep
      attr_reader :before_build

      def initialize(builder, image,
                     name:, package_name:, package_version:, package_cloud:,
                     prepare: [], build_dep: [], before_build: [])
        @builder = builder
        @image = image

        @name = name
        @package_name = package_name
        @package_version = package_version
        @package_cloud = package_cloud
        @prepare = prepare
        @build_dep = build_dep
        @before_build = before_build
      end

      def docker_image
        "#{builder.packager.docker_image || "buildizer/#{package_name}"}:#{name}"
      end

      def package_cloud_path
        "#{package_cloud}/#{image.os_package_cloud_name}/#{image.os_package_cloud_version}"
      end

      def image_build_path
        builder.build_path.join(name)
      end

      def image_runtime_build_path
        image_build_path.join('build')
      end
    end # Base
  end # Target
end # Buildizer
