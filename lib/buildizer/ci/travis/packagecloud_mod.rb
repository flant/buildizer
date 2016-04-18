module Buildizer
  module Ci
    class Travis
      module PackagecloudMod
        def packagecloud_var_name
          'PACKAGECLOUD'
        end

        def packagecloud_var
          repo.env_vars[packagecloud_var_name]
        end

        def packagecloud_var_upsert(**kwargs)
          repo.env_vars.upsert(packagecloud_var_name, kwargs.delete(:value), **kwargs)
        end

        def packagecloud_token_var_name(org: nil)
          if org
            "PACKAGECLOUD_TOKEN_#{org.upcase}"
          else
            'PACKAGECLOUD_TOKEN'
          end
        end

        def packagecloud_token_var(org: nil)
          repo.env_vars[packagecloud_token_var_name(org: org)]
        end

        def packagecloud_token_var_upsert(**kwargs)
          repo.env_vars.upsert(packagecloud_token_var_name(org: kwargs.delete(:org)),
                               kwargs.delete(:value),
                               **kwargs)
        end

        def packagecloud_repo_list
          packagecloud_var.value.split(',')
        end

        def packagecloud_setup!
          with_travis do
            packager.with_log(desc: "Travis packagecloud repo list") do |&fin|
              packagecloud_var_upsert(value: packager.packagecloud_repo_list.uniq.join(','),
                                             public: true)
              fin.call 'UPSERTED'
            end # with_log

            packager.packagecloud_org_desc_list.each do |desc|
              next unless desc[:token]
              packager.with_log(desc: "Travis packagecloud token for '#{desc[:org]}'") do |&fin|
                packagecloud_token_var_upsert(org: desc[:org], value: desc[:token], public: false)
                fin.call 'UPSERTED'
              end # with_log
            end
          end # with_travis
        end
      end # PackagecloudMod
    end # Travis
  end # Ci
end # Buildizer
