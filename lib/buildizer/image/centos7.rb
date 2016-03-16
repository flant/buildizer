module Buildizer
  module Image
    class Centos7 < Centos
      def initialize(docker, **kwargs)
        super(docker, 'centos7', **kwargs)
      end
    end # Centos7
  end # Image
end # Buildizer
