module Buildizer
  class Packager
    module PackageCloudMod
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

      def user_settings_package_cloud
        user_settings['package_cloud'] ||= {}
      end

      def user_settings_package_cloud_token
        user_settings_package_cloud['token'] ||= {}
      end

      def setup_package_cloud_repo_list
        Array(cli.options['package_cloud'])
      end

      def setup_package_cloud_repo_desc_list
        setup_package_cloud_repo_list.map do |repo|
          org, name = repo.split('/')
          {repo: repo, org: org, name: name, token: user_settings_package_cloud_token[org]}
        end
      end

      def setup_package_cloud_org_desc_list
        setup_package_cloud_repo_desc_list.map {|desc| {org: desc[:org], token: desc[:token]}}.uniq
      end

      def setup_package_cloud_org_list
        setup_package_cloud_repo_desc_list.map {|desc| desc[:org]}.uniq
      end

      def package_cloud_setup?
        !!cli.options['package_cloud']
      end

      def package_cloud_setup!
        return unless package_cloud_setup?

        update_user_settings = false
        setup_package_cloud_org_list.each do |org|
          if user_settings_package_cloud_token[org].nil? or
             cli.options['reset_package_cloud_token']
            token = cli.ask("Enter token for package_cloud org '#{org}':",
                             echo: false, default: 'none').tap{puts}
            token = (token == 'none' ? nil : token)
            if user_settings_package_cloud_token[org] != token
              user_settings_package_cloud_token[org] = token
              update_user_settings = true
            end
          end
        end
        user_settings_save! if update_user_settings

        ci.package_cloud_setup!
      end
    end # PackageCloudMod
  end # Packager
end # Buildizer
