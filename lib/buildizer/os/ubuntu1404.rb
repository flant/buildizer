module Buildizer
  module Os
    class Ubuntu1404 < Ubuntu
      def initialize(docker, **kwargs)
        super(docker, '14.04', **kwargs)
      end

      def os_codename
        'trusty'
      end
    end # Ubuntu1404
  end # Os
end # Buildizer
