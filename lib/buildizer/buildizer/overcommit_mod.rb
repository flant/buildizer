module Buildizer
  class Buildizer
    module OvercommitMod
      def overcommit_conf_path
        package_path.join('.overcommit.yml')
      end

      def overcommit_hooks_path
        package_path.join('.git-hooks')
      end

      def overcommit_hooks_pre_commit_path
        overcommit_hooks_path.join('pre_commit')
      end

      def overcommit_conf
        @overcommit_conf ||= overcommit_conf_path.load_yaml
      end

      def overcommit_conf_dump!
        write_yaml overcommit_conf_path, overcommit_conf
        command! 'overcommit --sign'
      end

      def overcommit_setup!
        overcommit_conf_dump!
        command! 'overcommit --install'
      end

      def overcommit_buildizer_require_list
        [].tap do |res|
          res << 'bundler/setup' if ENV.key? 'BUNDLE_BIN_PATH'
          res << 'buildizer'
        end
      end

      def overcommit_buildizer_require
        overcommit_buildizer_require_list.map {|req| "      require '#{req}'"}.join("\n")
      end

      def overcommit_verify_setup!
        hookcode = <<-HOOKCODE
module Overcommit::Hook::PreCommit
  class BuildizerVerify < Base
    def run
#{overcommit_buildizer_require}

      ::Buildizer::Buildizer.new.verify
      :pass
    rescue ::Buildizer::Error => e
      $stderr.puts e.net_status.net_status_message
      :fail
    end
  end
end
        HOOKCODE

        _overcommit_add_precommit!(:buildizer_verify, hookcode, desc: "Verify Buildizer conf file")
      end

      def overcommit_ci_setup!
        hookcode = <<-HOOKCODE
module Overcommit::Hook::PreCommit
  class BuildizerCiVerify < Base
    def run
#{overcommit_buildizer_require}

      Buildizer::Buildizer.new.ci.configuration_actual!
      :pass
    rescue ::Buildizer::Error => e
      $stderr.puts e.net_status.net_status_message
      :fail
    end
  end
end
        HOOKCODE

        _overcommit_add_precommit!(:buildizer_ci_verify, hookcode,
                                   desc: "Verify #{ci.ci_name} configuration is up to date")
      end

      def _overcommit_add_precommit!(name, hookcode, desc: nil, required: true)
        hook_name = name.to_s.split('_').map(&:capitalize).join
        overcommit_conf['PreCommit'] ||= {}
        overcommit_conf['PreCommit'][hook_name] = {}.tap do |hook|
          hook['enabled'] = true
          hook['required'] = required
          hook['desc'] = desc if desc
        end
        overcommit_conf_dump!

        path = overcommit_hooks_pre_commit_path.join("#{name}.rb")
        write_path path, hookcode
        command! 'overcommit --sign pre-commit'
      end
    end # OvercommitMod
  end # Buildizer
end # Buildizer
