module Buildizer
  module Target
    class Base
      attr_reader :builder
      attr_reader :os

      attr_reader :params

      attr_reader :build_image
      attr_reader :cache_image
      attr_reader :test_image

      def initialize(builder, os,
                     name:, package_name:, package_version:, package_cloud: [],
                     prepare: [], build_dep: [], before_build: [], maintainer: nil,
                     test_options: {}, test_env: {}, test_image: nil, before_test: [],
                     &blk)
        @builder = builder
        @os = os
        @params = {}

        params[:name] = name
        params[:package_name] = package_name
        params[:package_version] = package_version
        params[:package_cloud] = package_cloud
        params[:prepare] = prepare
        params[:build_dep] = build_dep
        params[:before_build] = before_build
        params[:maintainer] = maintainer
        params[:test_options] = test_options
        params[:test_env] = test_env
        params[:test_image] = test_image
        params[:before_test] = before_test

        yield if block_given?

        @build_image = ::Buildizer::Image.new(build_image_name, from: os.base_image_name)
        @cache_image = ::Buildizer::Image.new(cache_image_name) if cache_image_name
        @test_image = ::Buildizer::Image.new(test_image_name)
      end

      def method_missing(name, *args, &blk)
        param_name = name.to_sym
        if params.key? param_name
          params[param_name]
        else
          super
        end
      end

      def build_image_work_path
        raise
      end

      def container_package_name
        raise
      end

      def package_version_tag_param_name
        raise
      end

      def maintainer_email
        match = params[:maintainer].match(/<(.*)>/) if params[:maintainer]
        match[1] if match
      end

      def package_version
        params[:package_version].nil? ? nil : params[:package_version].to_s
      end

      def base_package_name
        params[:package_name].split('-').first
      end

      def build_image_tag
        params[:name].gsub('/', '__')
      end

      def build_image_name
        "#{params[:package_name]}:#{build_image_tag}"
      end

      def cache_image_name
        "#{os.docker.cache[:repo]}:#{build_image_tag}" if os.docker.cache
      end

      def test_image_name
        params[:test_image] || os.base_vendor_image_name
      end

      def package_cloud
        params[:package_cloud].map do |desc|
          desc.merge(package_path: _package_cloud_path(desc[:repo]))
        end
      end

      def _package_cloud_path(repo)
        "#{repo}/#{os.os_package_cloud_name}/#{os.os_package_cloud_version}"
      end

      def image_build_path
        build_image_work_path.join('build')
      end

      def image_extra_path
        build_image_work_path.join('extra')
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

      def test_env
        params[:test_env]
          .map {|var, values| Array(values).uniq.map {|value| {var => value}}}
          .reduce {|res, vars| res.product vars}
      end
    end # Base
  end # Target
end # Buildizer
