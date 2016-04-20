module Buildizer
  module Ci
    class Travis
      module DockerCacheMod
        class << self
          def included(base)
            base.class_eval do
              env_vars prefix: :docker_cache, repo: 'BUILDIZER_DOCKER_CACHE',
                                              user: 'BUILDIZER_DOCKER_CACHE_USERNAME',
                                              password: 'BUILDIZER_DOCKER_CACHE_PASSWORD',
                                              email: 'BUILDIZER_DOCKER_CACHE_EMAIL',
                                              server: 'BUILDIZER_DOCKER_CACHE_SERVER'
            end # class_eval
          end
        end # << self

        def docker_cache_setup!
          if packager.docker_cache_clear_settings?
            with_travis do
              packager.with_log(desc: "Travis docker cache settings") do |&fin|
                docker_cache_repo_var_delete!
                docker_cache_user_var_delete!
                docker_cache_password_var_delete!
                docker_cache_email_var_delete!
                docker_cache_server_var_delete!

                fin.call 'DELETED'
              end # with_log
            end # with_travis
          elsif packager.docker_cache_update_settings?
            with_travis do
              packager.with_log(desc: "Travis docker cache settings") do |&fin|
                docker_cache_repo_var_update! packager.setup_docker_cache_repo, public: true
                docker_cache_user_var_update! packager.setup_docker_cache_user, public: true
                docker_cache_password_var_update! packager.setup_docker_cache_password, public: false
                docker_cache_email_var_update! packager.setup_docker_cache_email, public: false
                docker_cache_server_var_update! packager.setup_docker_cache_server, public: true

                fin.call 'UPDATED'
              end # with_log
            end # with_travis
          end
        end
      end # DockerCacheMod
    end # Travis
  end # Ci
end # Buildizer
