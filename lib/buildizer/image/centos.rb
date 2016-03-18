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

      def native_build_instructions(builder, target)
        version, release = target.package_version.split('-')
        source_name = "#{target.package_name}-#{version}"
        source_archive_path = Pathname.new('/package.tar.gz')
        target_spec_name = "#{target.package_name}.spec"

        ["cp -r #{builder.docker.container_package_path} /tmp/#{source_name}",
         "cd /tmp",
         "tar -zcvf #{source_archive_path} #{source_name}",
         "ln -fs #{builder.docker.container_build_path} ~/rpmbuild",
         "rpmdev-setuptree",
         "cp #{source_archive_path} ~/rpmbuild/SOURCES",
         "cp #{builder.docker.container_package_path.join(target_spec_name)} ~/rpmbuild/SPECS",
         "cd ~/rpmbuild/SPECS",
         "rpmbuild -ba #{target_spec_name}",
         "cp $(find #{builder.docker.container_build_path.join('RPMS')} -name '*.rpm') #{builder.docker.container_build_path}",
        ]
      end
    end # Centos
  end # Image
end # Buildizer
