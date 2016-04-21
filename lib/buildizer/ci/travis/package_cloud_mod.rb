module Buildizer
  module Ci
    class Travis
      module PackageCloudMod
        class << self
          def included(base)
            base.class_eval do
              env_vars prefix: :package_cloud, repo_list: 'PACKAGECLOUD'
            end # class_eval
          end
        end # << self

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

        def package_cloud_token_var_delete!(**kwargs)
          var = package_cloud_token_var(**kwargs)
          var.delete if var
        end

        def package_cloud_token_var_update!(value, org: nil, **kwargs)
          if value
            repo.env_vars.upsert(package_cloud_token_var_name(org: org), value, **kwargs)
          else
            package_cloud_token_var_delete!(org: org)
          end
        end

        def package_cloud_setup!
          if buildizer.package_cloud_clear_settings?
            with_travis do
              repo_list = []
              repo_list = package_cloud_repo_list_var.value.split(',') if package_cloud_repo_list_var
              org_list = repo_list.map {|repo| repo.split('/').first}.uniq
              org_list.each do |org|
                buildizer.with_log(desc: "Travis package cloud token for '#{org}'") do |&fin|
                  package_cloud_token_var_delete! org: org
                  fin.call 'DELETED'
                end
              end

              buildizer.with_log(desc: "Travis package cloud repo list") do |&fin|
                package_cloud_repo_list_var_delete!
                fin.call 'DELETED'
              end
            end # with_travis
          elsif buildizer.package_cloud_update_settings?
            with_travis do
              buildizer.with_log(desc: "Travis package cloud repo list") do |&fin|
                package_cloud_repo_list_var_update! buildizer.setup_package_cloud_repo_list.join(','), public: true
                fin.call 'UPDATED'
              end # with_log

              buildizer.setup_package_cloud_org_desc_list.each do |desc|
                next unless desc[:token]
                buildizer.with_log(desc: "Travis package cloud token for '#{desc[:org]}'") do |&fin|
                  package_cloud_token_var_update! desc[:token], org: desc[:org], public: false
                  fin.call 'UPDATED'
                end # with_log
              end
            end # with_travis
          end
        end
      end # PackageCloudMod
    end # Travis
  end # Ci
end # Buildizer
