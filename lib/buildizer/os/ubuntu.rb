module Buildizer
  module Os
    class Ubuntu < Base
      attr_reader :version

      def initialize(docker, version, **kwargs)
        @version = version
        super(docker, **kwargs)
      end

      def name
        'ubuntu'
      end

      def codename
        raise
      end

      def package_cloud_os_version
        codename
      end

      def build_dep(image, build_dep)
        image.instruction :RUN, "apt-get build-dep -y #{build_dep.to_a.join(' ')}" if build_dep.any?
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

      def install_test_package_instructions(target)
        "(dpkg -i #{target.builder.docker.container_build_path.join('*.deb')} || true)" +
          " && apt-get install -qqyf"
      end

      def build_deb_instructions(target)
        ["DEB_BUILD_OPTIONS=nocheck dpkg-buildpackage -b -us -uc -j#{target.builder.build_jobs}",
         "cp ../*.deb #{target.builder.docker.container_build_path}"]
      end

      def native_build_instructions(target)
        source_archive_name = "#{target.package_name}_#{target.package_upstream_version}.orig.tar.gz"

        [["ln -fs #{target.container_package_archive_path} ",
          "#{target.container_package_path.dirname.join(source_archive_name)}"].join,
         "cd #{target.container_package_path}",
         *Array(build_deb_instructions(target))]
      end

      def patch_build_instructions(target)
        ["apt-get source #{target_package_spec(target)}",
         'cd $(ls *.orig.tar* | ruby -ne "puts \$_.split(\\".orig.tar\\").first.gsub(\\"_\\", \\"-\\")")',
         ["DEBFULLNAME=\"#{target.maintainer}\" DEBEMAIL=\"#{target.maintainer_email}\" ",
          "debchange --newversion ",
          "$(dpkg-parsechangelog | grep \"Version:\" | cut -d\" \" -f2-)buildizer#{target.patch_version} ",
          "--distribution #{codename} \"Patch by buildizer\""].join,
         *target.patch.map {|patch| "cp ../#{patch} debian/patches/"},
         *target.patch.map {|patch| "sed -i \"/#{Regexp.escape(patch)}/d\" debian/patches/series"},
         *target.patch.map {|patch| "echo #{patch} >> debian/patches/series"},
         *Array(build_deb_instructions(target))]
      end

      def target_package_spec(target)
        [target.package_name, target.package_version].compact.join('=')
      end
    end # Ubuntu
  end # Os
end # Buildizer
