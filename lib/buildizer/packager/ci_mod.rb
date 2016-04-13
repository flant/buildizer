module Buildizer
  class Packager
    module CiMod
      attr_reader :ci

      def _construct_ci
        res = raw_command! 'git config --get remote.origin.url'
        git_remote = res.stdout.strip
        if git_remote.start_with? 'http://'
          git_url = git_remote.split('http://', 2).last
        elsif git_remote.start_with? 'https://'
          git_url = git_remote.split('https://', 2).last
        else
          git_url = git_remote.split('@', 2).last
        end

        if git_url and git_url.start_with? 'github'
          Ci::Travis.new(self)
        elsif git_url and git_url.start_with? 'gitlab'
          Ci::GitlabCi.new(self)
        end
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
