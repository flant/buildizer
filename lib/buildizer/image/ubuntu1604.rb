module Buildizer
  module Image
    class Ubuntu1604 < Ubuntu
      def initialize(docker, **kwargs)
        super(docker, '16.04', **kwargs)
      end

      def os_codename
        'xenial'
      end
    end # Ubuntu1604
  end # Image
end # Buildizer
