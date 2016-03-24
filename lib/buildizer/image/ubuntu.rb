module Buildizer
  module Image
    class Ubuntu < Base
      attr_reader :os_version

      def initialize(docker, os_version, **kwargs)
        @os_version = os_version
        super(docker, **kwargs)
      end

      def os_name
        'ubuntu'
      end

      def os_codename
        raise
      end

      def os_package_cloud_version
        os_codename
      end

      def build_dep(build_dep)
        instruction :RUN, "apt-get build-dep -y #{build_dep.to_a.join(' ')}" if build_dep.any?
      end

      def fpm_output_type
        'deb'
      end

      def fpm_extra_params
        Array(super).tap do |res|
          res << '--deb-use-file-permissions'
          res << '--deb-no-default-config-files'
        end
      end

      def native_build_instructions(builder, target)
        source_archive_name = "#{target.package_name}_#{target.package_upstream_version}.orig.tar.gz"

        [["ln -fs #{target.container_package_archive_path} ",
          "#{target.container_package_path.dirname.join(source_archive_name)}"].join,
         "cd #{target.container_package_path}",
         "dpkg-buildpackage -us -uc",
         ["cp #{target.container_package_path.dirname.join('*.deb')} ",
          "#{builder.docker.container_build_path}"].join]
      end
    end # Ubuntu
  end # Image
end # Buildizer
