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
    end # Centos
  end # Image
end # Buildizer
