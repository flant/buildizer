module Buildizer
  module Image
    class Centos6 < Centos
      def initialize(docker, **kwargs)
        super(docker, 'centos6', **kwargs)
      end
    end # Centos6
  end # Image
end # Buildizer
