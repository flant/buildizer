module Buildizer
  module Ci
    class Travis
      module PackageCloudMod
        def package_cloud_var_name
          'PACKAGECLOUD'
        end

        def package_cloud_var
          repo.env_vars[package_cloud_var_name]
        end

        def package_cloud_var_upsert(**kwargs)
          repo.env_vars.upsert(package_cloud_var_name, kwargs.delete(:value), **kwargs)
        end

        def package_cloud_token_var_name(org: nil)
          if org
            "PACKAGECLOUD_TOKEN_#{org.upcase}"
          else
            'PACKAGECLOUD_TOKEN'
          end
        end

        def package_cloud_token_var(org: nil)
          repo.env_vars[package_cloud_token_var_name(org: org)]
        end

        def package_cloud_token_var_upsert(**kwargs)
          repo.env_vars.upsert(package_cloud_token_var_name(org: kwargs.delete(:org)),
                               kwargs.delete(:value),
                               **kwargs)
        end

        def setup_package_cloud_repo_list
          package_cloud_var.value.split(',')
        end

        def package_cloud_setup!
          with_travis do
            packager.with_log(desc: "Travis package_cloud repo list") do |&fin|
              package_cloud_var_upsert(value: packager.setup_package_cloud_repo_list.uniq.join(','),
                                       public: true)
              fin.call 'UPSERTED'
            end # with_log

            packager.setup_package_cloud_org_desc_list.each do |desc|
              next unless desc[:token]
              packager.with_log(desc: "Travis package_cloud token for '#{desc[:org]}'") do |&fin|
                package_cloud_token_var_upsert(org: desc[:org], value: desc[:token], public: false)
                fin.call 'UPSERTED'
              end # with_log
            end
          end # with_travis
        end
      end # PackageCloudMod
    end # Travis
  end # Ci
end # Buildizer
