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

        overcommit_hooks_pre_commit_path.mkpath
        path = overcommit_hooks_pre_commit_path.join('buildizer_verify.rb')
        write_path path, hookcode
        command! 'overcommit --sign pre-commit'

        overcommit_conf['PreCommit'] ||= {}
        overcommit_conf['PreCommit']['BuildizerVerify'] = {
          'enabled' => true,
          'required' => true,
          'desc' => "verify Buildizer conf file",
        }
        overcommit_conf_dump!
      end

      def overcommit_ci_setup!
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
