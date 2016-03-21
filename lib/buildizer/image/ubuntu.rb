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
        version, release = target.package_version.split('-')
        source_name = "#{target.package_name}-#{version}"
        source_archive_name = "#{target.package_name}_#{version}.orig.tar.gz"

        ["cp -r #{builder.docker.container_package_path} /tmp/#{source_name}",
         "cd /tmp",
         "tar -zcvf #{builder.docker.container_build_path.join(source_archive_name)} #{source_name}",
         "cd #{builder.docker.container_build_path}",
         "tar xf #{builder.docker.container_build_path.join(source_archive_name)}",
         "cd #{source_name}",
         "dpkg-buildpackage -us -uc"]
      end
    end # Ubuntu
  end # Image
end # Buildizer
