module Buildizer
  class Packager
    module DockerCacheMod
      def docker_cache
        return unless repo = ENV['BUILDIZER_DOCKER_CACHE']
        {username: ENV['BUILDIZER_DOCKER_CACHE_USERNAME'],
         password: ENV['BUILDIZER_DOCKER_CACHE_PASSWORD'],
         email: ENV['BUILDIZER_DOCKER_CACHE_EMAIL'],
         server: ENV['BUILDIZER_DOCKER_CACHE_SERVER'],
         repo: repo}
      end

      def docker_cache_settings
        user_settings['docker_cache'] ||= {}
      end

      def docker_cache_org_settings(org)
        docker_cache_settings['org'] ||= {}
        docker_cache_settings['org'][org] ||= {}
      end

      def docker_cache_user_settings(user)
        docker_cache_settings['user'] ||= {}
        docker_cache_settings['user'][user] ||= {}
      end

      def docker_cache_org_user_list(org)
        docker_cache_org_settings(org)['user'] ||= []
      end

      def docker_cache_org_repo_list(org)
        docker_cache_org_settings(org)['repo'] ||= []
      end

      def docker_cache_setup!
        return unless repo = cli.options['docker_cache']
        org, subname = repo.split('/')

        user = cli.options['docker_cache_user']
        user = docker_cache_org_user_list(org).first unless user
        raise Error, error: :input_error,
                     message: "docker cache user required" unless user
        raise Error, error: :input_error,
                     message: "bad docker cache user" if user.empty?

        if email = cli.options['docker_cache_email']
          docker_cache_user_settings(user)['email'] = email
        else
          email = docker_cache_user_settings(user)['email']
        end
        raise Error, error: :input_error,
                     message: 'docker cache email required' unless email
        raise Error, error: :input_error,
                     message: "bad docker cache email" unless email =~ /.+@.+/

        if cli.options['reset_docker_cache_password'] or
           (not password = docker_cache_user_settings(user)['password'])
          password = cli.ask("Docker cache user '#{user}' password:", echo: false).tap{puts}
          docker_cache_user_settings(user)['password'] = password
        end

        docker_cache_org_user_list(org).push(user) unless docker_cache_org_user_list(org).include? user
        docker_cache_org_repo_list(org).push(repo) unless docker_cache_org_repo_list(org).include? repo

        user_settings_save!

        ci.docker_cache_setup!
      end
    end # DockerCacheMod
  end # Packager
end # Buildizer
