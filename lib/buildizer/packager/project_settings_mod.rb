module Buildizer
  class Packager
    module ProjectSettingsMod
      using Refine

      def project_settings_path
        package_path.join('.buildizer.yml')
      end

      def project_settings
        @project_settings ||= begin
          (project_settings_path.load_yaml || {}).tap do |settings|
            settings['master'] = cli.options['master'] if cli.options.key? 'master'
          end
        end
      end

      def project_settings_setup!
        write_path(project_settings_path, YAML.dump(project_settings))
      end
    end # ProjectSettingsMod
  end # Packager
end # Buildizer
