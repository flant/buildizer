module Buildizer
  module Image
    class Centos < Base
      attr_reader :os_version

      def initialize(docker, os_version, **kwargs)
        @os_version = os_version
        super(docker, **kwargs)
      end

      def os_name
        'centos'
      end

      def os_package_cloud_name
        'el'
      end

      def os_package_cloud_version
        os_version.match(/\d+$/).to_s.to_i
      end

      def fpm_output_type
        'rpm'
      end

      def fpm_extra_params
        Array(super).tap do |res|
          res << '--rpm-use-file-permissions'
        end
      end

      def build_dep(build_dep)
        instruction :RUN, "yum-builddep -y #{build_dep.to_a.join(' ')}" if build_dep.any?
      end

      def add_repo(id:, name:, baseurl: nil, enabled: 1, gpgcheck: nil, gpgkey: nil, exclude: nil, includepkgs: nil, mirrorlist: nil)
        repo = "[#{id}]\
\\nname=#{name}\
\\nenabled=#{enabled}\
#{baseurl ? "\\nbaseurl=#{baseurl}" : nil}\
#{mirrorlist ? "\\nmirrorlist=#{mirrorlist}" : nil}\
#{gpgcheck ? "\\ngpgcheck=#{gpgcheck}" : nil}\
#{gpgkey ? "\\ngpgkey=#{gpgkey}" : nil}\
#{exclude ? "\\nexclude=#{exclude}" : nil}\
#{includepkgs ? "\\nincludepkgs=#{includepkgs}" : nil}"

        instruction :RUN, "bash -lec \"echo -e '#{repo}' >> /etc/yum.repos.d/CentOS-Extra-Buildizer.repo\""
      end

      def target_spec_name(target)
        "#{target.base_package_name}.spec"
      end

      def rpmdev_setuptree_instructions(builder, target)
        ["rpmdev-setuptree",
         "rmdir ~/rpmbuild/RPMS",
         "ln -fs #{builder.docker.container_build_path} ~/rpmbuild/RPMS"]
      end

      def build_rpm_instructions(builder, target)
        ["cd ~/rpmbuild/SPECS/",
         "rpmbuild -ba #{target_spec_name(target)} > /dev/null"]
      end

      def native_build_instructions(builder, target)
        [*rpmdev_setuptree_instructions(builder, target),
         "cp #{builder.docker.container_package_archive_path} ~/rpmbuild/SOURCES/",
         "cp #{builder.docker.container_package_path.join(target_spec_name(target))} ~/rpmbuild/SPECS/",
         *build_rpm_instructions(builder, target)]
      end

      def patch_build_instructions(builder, target)
        rpmchange_cmd = "rpmchange %{cmd} --specfile ~/rpmbuild/SPECS/#{target_spec_name(target)} %{args}"
        get_release_cmd = rpmchange_cmd % {cmd: :tag, args: "--name release"}
        set_release_cmd = rpmchange_cmd % {cmd: :tag, args: "--name release --value %{value}"}
        changelog_cmd = rpmchange_cmd % {
          cmd: :changelog,
          args: "--append --name \"%{name}\" --email \"%{email}\" --message \"%{message}\""
        }

        ["yum-builddep -y #{target.base_package_name}",
         *rpmdev_setuptree_instructions(builder, target),
         "yumdownloader --source #{target.package_name}",
         "rpm -i *.rpm",
         "gem install rpmchange",
         set_release_cmd % {value: "$(#{get_release_cmd})buildizer#{target.package_version}"},
         *target.patch.map {|patch| "cp #{patch} ~/rpmbuild/SOURCES/"},
         *target.patch.map {|patch|
           rpmchange_cmd % {cmd: :append, args: "--section prep --value \"patch -p1 < %{_sourcedir}/#{patch}\""}
         },
         changelog_cmd % {name: '', email: '', message: 'Patch by buildizer'}, # TODO: name (maintainer), email (maintainer_email)
         *build_rpm_instructions(builder, target)]
      end
    end # Centos
  end # Image
end # Buildizer
