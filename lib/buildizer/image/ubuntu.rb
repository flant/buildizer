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

      def build_deb_instructions(builder, target)
        ["DEB_BUILD_OPTIONS=nocheck dpkg-buildpackage -b -us -uc -j#{builder.build_jobs}",
         "echo dpkg-buildpackage DONE",
         "cp ../*.deb #{builder.docker.container_build_path}",
         "echo copy result deb DONE"]
      end

      def native_build_instructions(builder, target)
        source_archive_name = "#{target.package_name}_#{target.package_upstream_version}.orig.tar.gz"

        [["ln -fs #{target.container_package_archive_path} ",
          "#{target.container_package_path.dirname.join(source_archive_name)}"].join,
         "cd #{target.container_package_path}",
         *Array(build_deb_instructions(builder, target))]
      end

      def patch_build_instructions(builder, target)
        ["apt-get source #{target_package_spec(target)}",
         'cd $(ls *.orig.tar* | ruby -ne "puts \$_.split(\\".orig.tar\\").first.gsub(\\"_\\", \\"-\\")")',
         ["DEBFULLNAME="" DEBEMAIL="" debchange --newversion ",
          "$(dpkg-parsechangelog | grep \"Version:\" | cut -d\" \" -f2-)buildizer#{target.patch_version} ",
          "--distribution #{os_codename} \"Patch by buildizer\""].join,
         *target.patch.map {|patch| "cp ../#{patch} debian/patches/"},
         *target.patch.map {|patch| "sed -i \"/#{Regexp.escape(patch)}/d\" debian/patches/series"},
         *target.patch.map {|patch| "echo #{patch} >> debian/patches/series"},
         *Array(build_deb_instructions(builder, target))]
      end

      def target_package_spec(target)
        [target.package_name, target.package_version].compact.join('=')
      end
    end # Ubuntu
  end # Image
end # Buildizer
