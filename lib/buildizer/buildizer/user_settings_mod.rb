module Buildizer
  class Buildizer
    module UserSettingsMod
      def user_settings_path
        work_path.join('settings.yml')
      end

      def user_settings
        @user_settings ||= user_settings_path.load_yaml
      end

      def user_settings_save!
        write_yaml user_settings_path, user_settings
        user_settings_path.chmod(0600)
      end

      def user_settings_setup!
        user_settings_save!
      end
    end # UserSettingsMod
  end # Buildizer
end # Buildizer
