module Buildizer
  class Packager
    module ConfMod
      using Refine

      attr_reader :buildizer_conf_path

      def buildizer_conf
        @buildizer_conf ||= buildizer_conf_path.load_yaml
      end

      def buildizer_conf_update(conf)
        buildizer_conf.update conf
      end

      def buildizer_conf_setup!
        write_path(buildizer_conf_path, YAML.dump(buildizer_conf))
      end

      def package_name
        buildizer_conf['package_name']
      end

      def package_version
        buildizer_conf['package_version']
      end

      def package_version_tag_required_for_deploy?
        ENV['BUILDIZER_REQUIRE_TAG'].to_s.on?
      end

      def before_prepare
        Array(buildizer_conf['before_prepare'])
      end

      def after_prepare
        Array(buildizer_conf['after_prepare'])
      end

      def targets
        targets = Array(buildizer_conf['target'])
        restrict_targets = ENV['BUILDIZER_TARGET']
        restrict_targets = restrict_targets.split(',').map(&:strip) if restrict_targets
        targets = targets & restrict_targets if restrict_targets
        targets
      end

      def prepare
        Array(buildizer_conf['prepare'])
      end

      def build_dep
        Array(buildizer_conf['build_dep']).to_set
      end

      def before_build
        Array(buildizer_conf['before_build'])
      end

      def docker_server
        buildizer_conf['docker_server']
      end

      def docker_image
        buildizer_conf['image']
      end

      def package_cloud_repo
        ENV['PACKAGECLOUD'].to_s.split(',')
      end

      def package_cloud_org
        default_token = ENV['PACKAGECLOUD_TOKEN']
        package_cloud_repo.map {|repo| repo.split('/').first}.uniq.map do |org|
          [org, ENV["PACKAGECLOUD_TOKEN_#{org.upcase}"] || default_token]
        end.to_h
      end

      def package_cloud
        tokens = package_cloud_org
        package_cloud_repo.map do |repo|
          org = repo.split('/').first
          token = tokens[org]
          {org: org, repo: repo, token: token}
        end
      end

      def docker_cache
        return unless org = ENV['BUILDIZER_DOCKER_CACHE']
        {username: ENV['BUILDIZER_DOCKER_CACHE_USERNAME'],
         password: ENV['BUILDIZER_DOCKER_CACHE_PASSWORD'],
         email: ENV['BUILDIZER_DOCKER_CACHE_EMAIL'],
         server: ENV['BUILDIZER_DOCKER_CACHE_SERVER'],
         org: org}
      end

      def maintainer
        buildizer_conf['maintainer']
      end

      def package_version_tag
        ci.git_tag
      end

      def enabled?
        !!ci.git_tag
      end

      module Initialize
        def initialize(**kwargs)
          super(**kwargs)
          @buildizer_conf_path = package_path.join('Buildizer')
        end
      end # Initialize

      class << self
        def included(base)
          base.send(:prepend, Initialize)
        end
      end # << self
    end # ConfMod
  end # Packager
end # Buildizer
