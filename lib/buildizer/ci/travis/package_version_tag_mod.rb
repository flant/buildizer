module Buildizer
  module Ci
    class Travis
      module PackageVersionTagMod
        using Refine

        def require_tag_var_name
          'BUILDIZER_REQUIRE_TAG'
        end

        def require_tag_var
          repo.env_vars[require_tag_var_name]
        end

        def require_tag_var_upsert(**kwargs)
          repo.env_vars.upsert(require_tag_var_name, kwargs.delete(:value), public: true, **kwargs)
        end

        def require_tag_setup!
          with_travis do
            packager.with_log(desc: "Travis require tag for deploy") do |&fin|
              if packager.cli.options['require_tag'].nil?
                unless require_tag_var
                  require_tag_var_upsert(value: true.to_env)
                  fin.call 'ENABLED'
                else
                  fin.call
                end
              elsif packager.cli.options['require_tag']
                require_tag_var_upsert(value: true.to_env)
                fin.call 'ENABLED'
              else
                require_tag_var_upsert(value: false.to_env)
                fin.call 'DISABLED'
              end
            end # with_log
          end # with_travis
        end
      end # PackageVersionTagMod
    end # Travis
  end # Ci
end # Buildizer
