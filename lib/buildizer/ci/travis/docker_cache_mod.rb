module Buildizer
  module Ci
    class Travis
      module DockerCacheMod
        {repo: 'BUILDIZER_DOCKER_CACHE',
         user: 'BUILDIZER_DOCKER_CACHE_USERNAME',
         password: 'BUILDIZER_DOCKER_CACHE_PASSWORD',
         email: 'BUILDIZER_DOCKER_CACHE_EMAIL',
         server: 'BUILDIZER_DOCKER_CACHE_SERVER'}.each do |name, var_name|
          define_method("docker_cache_#{name}_var") {repo.env_vars[var_name]}
          define_method("docker_cache_#{name}_var_name") {var_name}
          define_method("docker_cache_#{name}_var_delete!") do
            var = send("docker_cache_#{name}_var")
            var.delete if var
          end
          define_method("docker_cache_#{name}_var_update!") do |value, **kwargs|
            if value
              repo.env_vars.upsert(var_name, value, **kwargs)
            else
              send("docker_cache_#{name}_var_delete!")
            end
          end
        end

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
                docker_cache_user_var_update! packager.setup_docker_cache_user, public: false
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
