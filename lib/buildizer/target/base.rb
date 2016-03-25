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

        image_work_path.mkpath
        image_build_path.mkpath
        image_extra_path.mkpath
      end

      def docker_image
        "#{builder.packager.docker_image || "buildizer/#{package_name}"}:#{name}"
      end

      def package_cloud_path
        "#{package_cloud}/#{image.os_package_cloud_name}/#{image.os_package_cloud_version}"
      end

      def image_work_path
        builder.work_path.join(package_name).join(package_version).join(name)
      end

      def image_build_path
        image_work_path.join('build')
      end

      def image_extra_path
        image_work_path.join('extra')
      end

      def package_upstream_version
        package_version.split('-')[0]
      end

      def package_release
        package_version.split('-')[1]
      end

      def package_upstream_source_name
        "#{package_name}-#{package_upstream_version}"
      end

      def package_upstream_source_archive_name
        "#{package_upstream_source_name}.tar.gz"
      end

      def container_package_path
        Pathname.new('/').join(package_upstream_source_name)
      end

      def container_package_archive_path
        Pathname.new('/').join(package_upstream_source_archive_name)
      end
    end # Base
  end # Target
end # Buildizer
