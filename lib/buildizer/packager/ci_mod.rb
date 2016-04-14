module Buildizer
  class Packager
    module CiMod
      attr_reader :ci

      def _construct_ci
        unless ci_name = options['ci']
          git_remote = git_remote_url.to_s
          if git_remote.start_with? 'http://'
            git_host = git_remote.split('http://', 2).last
          elsif git_remote.start_with? 'https://'
            git_host = git_remote.split('https://', 2).last
          else
            git_host = git_remote.split('@', 2).last
          end

          if git_host and git_host.start_with? 'github'
            ci_name = 'travis'
          elsif git_host and git_host.start_with? 'gitlab'
            ci_name = 'gitlab-ci'
          else
            raise Error, error: :input_error,
                         message: "unable to determine ci to use (use --ci stored option)"
          end
        end

        klass = {'travis' => Ci::Travis,
                 'gitlab-ci' => Ci::GitlabCi}[ci_name.to_s.downcase]
        raise(Error, error: :input_error,
                     message: "unknown ci '#{ci_name}' (use travis or gitlab-ci)") unless klass
        klass.new(self)
      end

      module Initialize
        def initialize(**kwargs)
          super(**kwargs)
          @ci = _construct_ci
        end
      end # Initialize

      class << self
        def included(base)
          base.send(:prepend, Initialize)
        end
      end # << self
    end # CiMod
  end # Packager
end # Buildizer
