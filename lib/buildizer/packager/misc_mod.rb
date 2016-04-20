module Buildizer
  class Packager
    module MiscMod
      def command(*args, do_raise: false, log_failure: nil, **kwargs)
        if debug
          Shellfold.run(*args, log_failure: log_failure, **kwargs).tap do |cmd|
            if not cmd.status.success? and do_raise
              raise Error.new(error: :error, message: "external command error")
            end
          end
        else
          raw_command(*args, do_raise: do_raise, **kwargs)
        end
      end

      def command!(*args, **kwargs)
        command(*args, do_raise: true, log_failure: true, **kwargs)
      end

      def raw_command(*args, do_raise: false, **kwargs)
        Mixlib::ShellOut.new(*args, **kwargs).tap do |cmd|
          cmd.run_command
          if not cmd.status.success? and do_raise
            raise Error.new(error: :error,
                            message: "external command error: " +
                                     [args.join(' '),
                                      cmd.stdout + cmd.stderr].reject(&:empty?).join(' => '))
          end
        end
      end

      def raw_command!(*args, **kwargs)
        raw_command(*args, do_raise: true, **kwargs)
      end

      def write_path(path, value)
        with_log(desc: "Write path #{path}") do |&fin|
          recreate = path.exist?
          if path.exist?
            if path.read == value
              fin.call 'OK'
            else
              path.write value
              fin.call 'UPDATED'
            end
          else
            path.write value
            fin.call 'CREATED'
          end
        end
      end

      def with_log(desc: nil, &blk)
        puts("   #{desc}") if debug and desc
        blk.call do |status|
          puts("=> #{desc} [#{status || 'OK'}]") if debug and desc
        end
      end
    end # MiscMod
  end # Packager
end # Buildizer
