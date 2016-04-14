module Buildizer
  module Cli
    module HelperMod
      def ask_setup_conf_file?(path)
        do_setup_conf_file_default = (path.exist? ? "no" : "yes")
        do_setup_conf_file = ask(
          (path.exist? ? "#{path} exists. Do setup?" : "#{path} does not exist. Do setup?"),
          limited_to: ["yes", "no"],
          default: do_setup_conf_file_default
        )
        do_setup_conf_file == "yes"
      end

      def ask_yes_no?(question, default: nil)
        ask(question, limited_to: ["yes", "no"],
                      default: (default.nil? ? "yes" : (default ? "yes" : "no"))) == "yes"
      end
    end # HelperMod
  end # Cli
end # Buildizer
