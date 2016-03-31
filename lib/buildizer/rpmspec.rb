module Buildizer
  class Rpmspec
    SECTIONS = %i{prep build install clean check files changelog}

    def initialize(path)
      @path = Pathname.new(path).expand_path
      _load
    end

    def sections
      @sections ||= {}
    end

    def preamble_lines
      @preamble_lines ||= []
    end

    SECTIONS.each do |section|
      define_method("#{section}_lines") {(sections[section] || {}).values.flatten}
    end

    def save!
    end

    def reload
      @sections = nil
    end

    def dump
      [].tap do |res|
        res.push *preamble_lines
        sections.each do |section, by_params|
          by_params.each {|params, lines|
            res.push ["%#{section}", *params].join(' ')
            res.push *lines
          }
        end
      end.map {|line| line + "\n"}.join
    end

    def version
      find_tag(preamble_lines, :Version)
    end

    def release
      find_tag(preamble_lines, :Release)
    end

    def find_tag(tag)
      match = preamble_lines.find {|line| line.start_with? "#{tag}:"}
      match.split(': ').last if match
    end

    def append_tag(tag, value)
    end

    def patches_tags
      preamble_lines
        .grep(_patch_line_regex)
        .map(&method(:_patch_line_parse))
        .to_h
    end

    def append_patch_tag(value)
      i = preamble_lines
        .reverse_each
        .find_index {|line| line =~ _patch_line_regex}
      if i
        last_patch_i = preamble_lines.size - i - 1
        last_patch = _patch_line_parse(preamble_lines[last_patch_i]).first
        preamble_lines.insert(last_patch_i + 1, "Patch#{last_patch + 1}: #{value}")
      else
        preamble_lines << "Patch0: #{value}"
      end
    end

    protected

    def _patch_line_parse(line)
      tag, value = line.split(': ', 2)
      [tag.split('Patch').last.to_i, value]
    end

    def _patch_line_regex
      @_patch_line_regex ||= /Patch[0-9]*: /
    end

    def _load
      current_section = preamble_lines
      @path.readlines.each do |line|
        line.chomp!
        if section = SECTIONS.find {|s| line.start_with? "%#{s}"}
          section_params = line.split(' ')[1..-1]
          section_key = section_params.empty? ? nil : section_params
          sections[section] ||= {}
          sections[section][section_key] ||= []
          current_section = sections[section][section_key]
        else
          current_section << line
        end
      end
    end
  end # Rpmspec
end # Buildizer

__END__
rpmspec = Rpmspec.new('aaa')

rpmspec.preamble_lines
rpmspec.prep_lines
rpmspec.build_lines
rpmspec.install_lines
rpmspec.check_lines
rpmspec.files_lines
rpmspec.clean_lines
rpmspec.changelog_lines

rpmspec.append_patch patch_path
rpmspec.append_patch 'mypatch.path'
rpmspec.release
rpmspec.version
rpmspec.release = "#{rpmspec.release}buildizer#{buildizer_release}"
rpmspec.append_changelog name: 'Timofey Kirillov',
                         email: 'timofey.kirillov@flant.com',
                         messsage: 'Buildizer release'
