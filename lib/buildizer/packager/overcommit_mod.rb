module Buildizer
  class Packager
    module OvercommitMod
      using Refine

      attr_reader :overcommit_conf_path
      attr_reader :overcommit_hooks_path

      def overcommit_hooks_pre_commit_path
        overcommit_hooks_path.join('pre_commit')
      end

      def overcommit_conf
        @overcommit_conf ||= overcommit_conf_path.load_yaml
      end

      def overcommit_conf_raw
        YAML.dump(overcommit_conf)
      end

      def overcommit_conf_dump!
        write_path overcommit_conf_path, overcommit_conf_raw
        command! 'overcommit --sign'
      end

      def overcommit_setup!
        overcommit_hooks_path.mkpath
        overcommit_conf_dump!
        command! 'overcommit --install'
      end

      def overcommit_verify_setup!
        hookcode = <<-HOOKCODE
module Overcommit::Hook::PreCommit
  class BuildizerVerify < Base
    def run
      return :fail unless system("buildizer verify")
      :pass
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
      return :fail unless system("buildizer setup ci --verify")
      :pass
    end
  end
end
        HOOKCODE

        _overcommit_add_precommit!(:buildizer_ci_verify, hookcode,
                                   desc: "Verify #{ci.ci_name} configuration is up to date")
      end

      def _overcommit_add_precommit!(name, hookcode, desc: nil, required: true)
        overcommit_hooks_pre_commit_path.mkpath
        path = overcommit_hooks_pre_commit_path.join("#{name}.rb")
        write_path path, hookcode
        command! 'overcommit --sign pre-commit'

        hook_name = name.to_s.split('_').map(&:capitalize).join
        overcommit_conf['PreCommit'] ||= {}
        overcommit_conf['PreCommit'][hook_name] = {}.tap do |hook|
          hook['enabled'] = true
          hook['required'] = required
          hook['desc'] = desc if desc
        end
        overcommit_conf_dump!
      end

      module Initialize
        def initialize(**kwargs)
          super(**kwargs)
          @overcommit_conf_path = package_path.join('.overcommit.yml')
          @overcommit_hooks_path = package_path.join('.git-hooks')
        end
      end # Initialize

      class << self
        def included(base)
          base.send(:prepend, Initialize)
        end
      end # << self
    end # OvercommitMod
  end # Packager
end # Buildizer
