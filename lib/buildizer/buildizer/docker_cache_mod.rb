module Buildizer
  class Buildizer
    module DockerCacheMod
      def docker_cache
        return unless repo = ENV['BUILDIZER_DOCKER_CACHE']
        {user: ENV['BUILDIZER_DOCKER_CACHE_USERNAME'],
         password: ENV['BUILDIZER_DOCKER_CACHE_PASSWORD'],
         email: ENV['BUILDIZER_DOCKER_CACHE_EMAIL'],
         server: ENV['BUILDIZER_DOCKER_CACHE_SERVER'],
         repo: repo}
      end

      def setup_docker_cache_repo
        options[:docker_cache]
      end

      def setup_docker_cache_org
        setup_docker_cache_repo.split('/').first
      end

      def setup_docker_cache_user
        options[:docker_cache_user] || user_settings_docker_cache_user_list(setup_docker_cache_org).first
      end

      def setup_docker_cache_password
        @setup_docker_cache_password ||= begin
          settings_password = user_settings_docker_cache_user(setup_docker_cache_user)['password']
          if options[:reset_docker_cache_password] or settings_password.nil?
            secure_option(
              :docker_cache_password,
              ask: "Docker cache user '#{setup_docker_cache_user}' password:"
            )
          else
            settings_password
          end
        end
      end

      def setup_docker_cache_email
        options[:docker_cache_email] || user_settings_docker_cache_user(setup_docker_cache_user)['email']
      end

      def setup_docker_cache_server
        options[:docker_cache_server] || user_settings_docker_cache_user(setup_docker_cache_user)['server']
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

      def docker_cache_update_settings?
        not setup_docker_cache_repo.nil?
      end

      def docker_cache_clear_settings?
        options[:clear_docker_cache]
      end

      def docker_cache_setup!
        if docker_cache_update_settings?
          raise Error, error: :input_error,
                       message: "docker cache user required" unless setup_docker_cache_user
          raise Error, error: :input_error,
                       message: "bad docker cache user" if setup_docker_cache_user.empty?

          user_list = user_settings_docker_cache_user_list(setup_docker_cache_org)
          user_list.push(setup_docker_cache_user) unless user_list.include? setup_docker_cache_user

          raise Error, error: :input_error,
                       message: 'docker cache email required' unless setup_docker_cache_email
          raise Error, error: :input_error,
                       message: "bad docker cache email" unless setup_docker_cache_email =~ /.+@.+/

          user_settings_docker_cache_user(setup_docker_cache_user)['email'] = setup_docker_cache_email
          user_settings_docker_cache_user(setup_docker_cache_user)['server'] = setup_docker_cache_server
          user_settings_docker_cache_user(setup_docker_cache_user)['password'] = setup_docker_cache_password

          repo_list = user_settings_docker_cache_repo_list(setup_docker_cache_org)
          repo_list.push(setup_docker_cache_repo) unless repo_list.include? setup_docker_cache_repo

          user_settings_save!
        end

        ci.docker_cache_setup!
      end
    end # DockerCacheMod
  end # Buildizer
end # Buildizer
