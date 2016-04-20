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

      def user_settings_docker_cache
        user_settings['docker_cache'] ||= {}
      end

      def user_settings_docker_cache_org(org)
        user_settings_docker_cache['org'] ||= {}
        user_settings_docker_cache['org'][org] ||= {}
      end

      def user_settings_docker_cache_user(user)
        user_settings_docker_cache['user'] ||= {}
        user_settings_docker_cache['user'][user] ||= {}
      end

      def user_settings_docker_cache_user_list(org)
        user_settings_docker_cache_org(org)['user'] ||= []
      end

      def user_settings_docker_cache_repo_list(org)
        user_settings_docker_cache_org(org)['repo'] ||= []
      end

      def docker_cache_setup!
        return unless repo = cli.options['docker_cache']
        org, subname = repo.split('/')

        user = cli.options['docker_cache_user']
        user = user_settings_docker_cache_user_list(org).first unless user
        raise Error, error: :input_error,
                     message: "docker cache user required" unless user
        raise Error, error: :input_error,
                     message: "bad docker cache user" if user.empty?

        if email = cli.options['docker_cache_email']
          user_settings_docker_cache_user(user)['email'] = email
        else
          email = user_settings_docker_cache_user(user)['email']
        end
        raise Error, error: :input_error,
                     message: 'docker cache email required' unless email
        raise Error, error: :input_error,
                     message: "bad docker cache email" unless email =~ /.+@.+/

        if cli.options['reset_docker_cache_password'] or
           (not password = user_settings_docker_cache_user(user)['password'])
          password = cli.ask("Docker cache user '#{user}' password:", echo: false).tap{puts}
          user_settings_docker_cache_user(user)['password'] = password
        end

        user_settings_docker_cache_user_list(org).push(user) unless user_settings_docker_cache_user_list(org).include? user
        user_settings_docker_cache_repo_list(org).push(repo) unless user_settings_docker_cache_repo_list(org).include? repo

        user_settings_save!

        ci.docker_cache_setup!
      end
    end # DockerCacheMod
  end # Packager
end # Buildizer
