module Buildizer
  class Buildizer
    module GitMod
      def git_available?
        res = raw_command 'git status'
        res.status.success?
      end

      def git_remote_url
        return unless git_available?
        res = raw_command 'git config --get remote.origin.url'
        res.stdout.strip
      end
    end # GitMod
  end # Buildizer
end # Buildizer
