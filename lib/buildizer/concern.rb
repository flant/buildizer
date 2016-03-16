module Buildizer
  module Concern
    def self.included(base)
      base.send(:extend, ClassMethods) if defined? ClassMethods
    end

    def command(*command_args, do_raise: nil)
      p command_args
      Mixlib::ShellOut.new(*command_args).tap do |cmd|
        cmd.live_stdout = $stdout
        cmd.run_command
        if not cmd.status.success? and do_raise
          raise Error.new(error: :error, message: [cmd.stdout, cmd.stderr].join("\n"))
        end
        cmd
      end
    end

    def command!(*command_args)
      command(*command_args, do_raise: true)
    end
  end # Concern
end # Buildizer
