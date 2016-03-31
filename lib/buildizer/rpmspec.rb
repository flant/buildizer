module Buildizer
  class Rpmspec
    SECTIONS = %i{prep build install clean check files changelog}

    attr_reader :path

    def initialize(path)
      @path = Pathname.new(path).expand_path
      _load
    end

    def reload
      @sections = nil
    end

    def save!
      path.write dump
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

    def patch_tags
      preamble_lines
        .grep(_patch_line_regex)
        .map(&method(:_patch_line_parse))
        .to_h
    end

    def append_patch_tag(value)
      patch_num = nil
      make_line = proc do |insert_ind|
        if insert_ind > 0
          last_patch_num = _patch_line_parse(preamble_lines[insert_ind - 1]).first
          patch_num = last_patch_num + 1
        else
          patch_num = 0
        end
        "Patch#{patch_num}: #{value}"
      end
      _append_line(into: preamble_lines, value: make_line, after: _patch_line_regex)
      patch_num
    end

    def append_apply_patch(num)
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

    protected

    def _append_line(into:, value:, after: nil)
      find_index = proc do |lines|
        if after
          ind = lines.rindex {|line| line.to_s =~ after}
          ind ? ind + 1 : -1
        else
          -1
        end
      end
      _insert_line(into: into, value: value, find_index: find_index)
    end

    def _prepend_line(into:, value:, before: nil)
      find_index = proc do |lines|
        if before
          lines.index {|line| line.to_s =~ before} || 0
        else
          0
        end
      end
      _insert_line(into: into, value: value, find_index: find_index)
    end

    def _insert_line(into:, value:, find_index:)
      if ind = find_index.call(into)
        line = (value.respond_to?(:call) ? value.call(ind) : value).to_s.chomp
        into.insert(ind, line)
      end
    end

    def _patch_line_parse(line)
      tag, value = line.split(': ', 2)
      [tag.split('Patch').last.to_i, value] if tag
    end

    def _patch_line_regex
      @_patch_line_regex ||= /Patch[0-9]*: /
    end

    def _load
      current_section = preamble_lines
      path.readlines.each do |line|
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
