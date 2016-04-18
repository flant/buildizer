module Buildizer
  class Packager
    module PackagecloudMod
      def packagecloud_repo_list
        Array(cli.options['packagecloud'])
      end

      def user_settings_packagecloud
        user_settings['packagecloud'] ||= {}
      end

      def user_settings_packagecloud_token
        user_settings_packagecloud['token'] ||= {}
      end

      def packagecloud_repo_desc_list
        packagecloud_repo_list.map do |repo|
          org, name = repo.split('/')
          {repo: repo, org: org, name: name, token: user_settings_packagecloud_token[org]}
        end
      end

      def packagecloud_org_desc_list
        packagecloud_repo_desc_list.map {|desc| {org: desc[:org], token: desc[:token]}}.uniq
      end

      def packagecloud_org_list
        packagecloud_repo_desc_list.map {|desc| desc[:org]}.uniq
      end

      def packagecloud_setup!
        update_user_settings = false
        packagecloud_org_list.each do |org|
          if user_settings_packagecloud_token[org].nil? or
             cli.options['reset_packagecloud_token']
            token = cli.ask("Enter token for packagecloud org '#{org}':",
                             echo: false, default: 'none').tap{puts}
            token = (token == 'none' ? nil : token)
            if user_settings_packagecloud_token[org] != token
              user_settings_packagecloud_token[org] = token
              update_user_settings = true
            end
          end
        end
        user_settings_save! if update_user_settings

        ci.packagecloud_setup!
      end
    end # PackagecloudMod
  end # Packager
end # Buildizer
