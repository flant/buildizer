module Buildizer
  module Ci
    class Travis
      module DockerCacheMod
        def docker_cache
          #TODO
        end

        def docker_cache_setup!
          with_travis do
            packager.with_log(desc: "Travis docker cache settings") do |&fin|
              #TODO
            end # with_log
          end # with_travis
        end
      end # DockerCacheMod
    end # Travis
  end # Ci
end # Buildizer
