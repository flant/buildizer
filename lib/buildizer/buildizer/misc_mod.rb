module Buildizer
  class Buildizer
    module MiscMod
      def command(*args, do_raise: false, **kwargs)
        Shellfold.run(*args, live_log: debug, **kwargs).tap do |cmd|
          if not cmd.status.success? and do_raise
            raise Error.new(error: :error, message: "external command error")
          end
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
              path.write! value
              fin.call 'UPDATED'
            end
          else
            path.write! value
            fin.call 'CREATED'
          end
        end
      end

      def write_yaml(path, cfg)
        with_log(desc: "Update config #{path}") do |&fin|
          old_cfg = path.load_yaml
          if old_cfg == cfg
            fin.call 'OK'
          elsif cfg.empty?
            if path.exist?
              path.delete
              fin.call 'DELETED'
            else
              fin.call 'OK'
            end
          else
            if path.exist?
              path.dump_yaml(cfg)
              fin.call 'UPDATED'
            else
              path.dump_yaml(cfg)
              fin.call 'CREATED'
            end
          end
        end
      end

      def with_log(desc: nil, &blk) # TODO: rename to verbose
        puts("   #{desc}") if desc
        blk.call do |status|
          puts("=> #{desc} [#{status || 'OK'}]") if desc
        end
      end

      def warn(msg)
        Kernel::warn msg.to_s.colorize(:yellow)
      end
    end # MiscMod
  end # Buildizer
end # Buildizer
