module Buildizer
  class Image
    attr_reader :name
    attr_reader :target

    attr_reader :instructions
    attr_reader :from

    def initialize(name, target, from: nil)
      @name = name
      @target = target

      @instructions = []
      @from = from

      instruction :FROM, from if from
    end

    def instruction(instruction, cmd)
      instructions << [instruction.to_s.upcase, cmd].join(' ')
    end

    def build_path
      target.image_build_path
    end

    def extra_path
      target.image_extra_path
    end

    def dockerfile_name
      "#{name}.dockerfile"
    end

    def dockerfile_path
      target.image_work_path.join(dockerfile_name)
    end

    def dockerfile_dump
      [instructions, nil].join("\n")
    end

    def dockerfile_write!
      dockerfile_path.write! dockerfile_dump
    end
  end # Image
end # Buildizer
