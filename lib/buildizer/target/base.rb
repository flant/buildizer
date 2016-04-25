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
      attr_reader :maintainer

      attr_reader :test_options
      attr_reader :test_env
      attr_reader :before_test

      def initialize(builder, image,
                     name:, package_name:, package_version:, package_cloud: [],
                     prepare: [], build_dep: [], before_build: [], maintainer: nil,
                     test_options: {}, test_env: {}, before_test: [],
                     &blk)
        @builder = builder
        @image = image

        @name = name
        @package_name = package_name
        @package_version = package_version
        @package_cloud = package_cloud
        @prepare = prepare
        @build_dep = build_dep
        @before_build = before_build
        @maintainer = maintainer

        @test_options = test_options
        @test_env = test_env
        @before_test = before_test

        yield if block_given?
      end

      def image_work_path
        raise
      end

      def container_package_name
        raise
      end

      def package_version_tag_param_name
        raise
      end

      def maintainer_email
        match = maintainer.match(/<(.*)>/) if maintainer
        match[1] if match
      end

      def package_version
        @package_version.nil? ? nil : @package_version.to_s
      end

      def base_package_name
        package_name.split('-').first
      end

      def docker_image_repository
        package_name
      end

      def docker_image_tag
        name.gsub('/', '__')
      end

      def docker_image
        "#{docker_image_repository}:#{docker_image_tag}"
      end

      def docker_cache_image
        "#{image.docker.cache[:repo]}:#{docker_image_tag}" if image.docker.cache
      end

      def package_cloud
        @package_cloud.map do |desc|
          desc.merge(package_path: _package_cloud_path(desc[:repo]))
        end
      end

      def _package_cloud_path(repo)
        "#{repo}/#{image.os_package_cloud_name}/#{image.os_package_cloud_version}"
      end

      def image_build_path
        image_work_path.join('build')
      end

      def image_extra_path
        image_work_path.join('extra')
      end

      def package_version_tag
        send(package_version_tag_param_name)
      end

      def container_package_archive_name
        "#{container_package_name}.tar.gz"
      end

      def container_package_path
        Pathname.new('/').join(container_package_name)
      end

      def container_package_archive_path
        Pathname.new('/').join(container_package_archive_name)
      end
    end # Base
  end # Target
end # Buildizer
