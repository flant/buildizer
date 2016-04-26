module Buildizer
  module Os
    class Centos < Base
      attr_reader :version

      def initialize(docker, version, **kwargs)
        @version = version
        super(docker, **kwargs)
      end

      def name
        'centos'
      end

      def package_cloud_os_name
        'el'
      end

      def package_cloud_os_version
        version.match(/\d+$/).to_s.to_i
      end

      def fpm_output_type
        'rpm'
      end

      def fpm_extra_params
        Array(super).tap do |res|
          res << '--rpm-use-file-permissions'
        end
      end

      def build_dep(image, build_dep)
        image.instruction :RUN, "yum-builddep -y #{build_dep.to_a.join(' ')}" if build_dep.any?
      end

      def add_repo(image, id:, name:, baseurl: nil, enabled: 1, gpgcheck: nil, gpgkey: nil, exclude: nil, includepkgs: nil, mirrorlist: nil)
        repo = "[#{id}]\
\\nname=#{name}\
\\nenabled=#{enabled}\
#{baseurl ? "\\nbaseurl=#{baseurl}" : nil}\
#{mirrorlist ? "\\nmirrorlist=#{mirrorlist}" : nil}\
#{gpgcheck ? "\\ngpgcheck=#{gpgcheck}" : nil}\
#{gpgkey ? "\\ngpgkey=#{gpgkey}" : nil}\
#{exclude ? "\\nexclude=#{exclude}" : nil}\
#{includepkgs ? "\\nincludepkgs=#{includepkgs}" : nil}"

        image.instruction :RUN, "bash -lec \"echo -e '#{repo}' >> /etc/yum.repos.d/CentOS-Extra-Buildizer.repo\""
      end

      def target_spec_name(target)
        "#{target.base_package_name}.spec"
      end

      def rpmdev_setuptree_instructions(target)
        "rpmdev-setuptree"
      end

      def build_rpm_instructions(target)
        ["cd ~/rpmbuild/SPECS/",
         "rpmbuild -bb #{target_spec_name(target)}",
         ["find ~/rpmbuild/RPMS -name '*.rpm' ",
          "-exec mv {} #{target.builder.docker.container_build_path} \\;"].join]
      end

      def native_build_instructions(target)
        [*Array(rpmdev_setuptree_instructions(target)),
         "cp #{target.builder.docker.container_package_archive_path} ~/rpmbuild/SOURCES/",
         "cp #{target.builder.docker.container_package_path.join(target_spec_name(target))} ~/rpmbuild/SPECS/",
         *Array(build_rpm_instructions(target))]
      end

      def patch_build_instructions(target)
        rpmchange_cmd = "rpmchange %{cmd} --specfile ~/rpmbuild/SPECS/#{target_spec_name(target)} %{args}"
        get_release_cmd = rpmchange_cmd % {cmd: :tag, args: "--name release"}
        set_release_cmd = rpmchange_cmd % {cmd: :tag, args: "--name release --value %{value}"}
        changelog_cmd = rpmchange_cmd % {
          cmd: :changelog,
          args: "--append --name \"%{name}\" --email \"%{email}\" --message \"%{message}\""
        }

        [*Array(rpmdev_setuptree_instructions(target)),
         "yumdownloader --source #{target_package_spec(target)}",
         "rpm -i *.rpm",
         "gem install rpmchange",
         set_release_cmd % {value: "$(#{get_release_cmd})buildizer#{target.package_version}"},
         *target.patch.map {|patch| "cp #{patch} ~/rpmbuild/SOURCES/"},
         *target.patch.map {|patch|
           rpmchange_cmd % {cmd: :append,
                            args: "--section prep --value \"patch -p1 < %{_sourcedir}/#{patch}\""}
         },
         changelog_cmd % {name: target.maintainer,
                          email: target.maintainer_email,
                          message: 'Patch by buildizer'},
         *Array(build_rpm_instructions(target))]
      end

      def target_package_spec(target)
        [target.package_name, target.package_version].compact.join('-')
      end
    end # Centos
  end # Os
end # Buildizer
