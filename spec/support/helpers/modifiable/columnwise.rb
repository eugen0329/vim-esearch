# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
module Helpers::Modifiable::Columnwise
  shared_context 'setup columnwise testing contexts' do
    let(:contexts) do
      3.times
       .map { build_context(alphabet, fillers_alphabet) }
       .sort_by(&:name)
    end
    let(:files) { contexts.map { |c| file(c.content, c.name) } }
    let(:fillers_alphabet) { '_.+'.chars }
    let(:alphabet) { ('a'..'z').to_a + '()[]-,^&$#@!?*~`/\'"'.chars }
  end

  shared_context 'setup columnwise testing' do |from, to|
    include_context 'setup columnwise testing contexts'

    let(:from_ctx) { ctx_index(from) }
    let(:to_ctx) { ctx_index(to) }
    let(:from_entry) { entry_index(from) }
    let(:to_entry) { entry_index(to) }
    let(:affected_entries) { entries_from_range(from, to) }
    let(:unaffected_entries) { entries - affected_entries }

    let(:bounds) { [line_in_window(from), line_in_window(to)].reverse.reverse }
    let(:from_line) { bounds.first }
    let(:to_line)   { bounds.last }

    let(:ctx1) { contexts[from_ctx] }
    let(:ctx2) { contexts[to_ctx] }
    let(:entry1) { ctx1.entries[from_entry] }
    let(:entry2) { ctx2.entries[to_entry] }
  end

  AnchoredEntry = Struct.new(:relative_path, :index, :line_in_file, :content, :anchors) do
    delegate :line_content, :result_text, to: :parsed_entry

    def text_before(anchor)
      content.partition(anchors[anchor]).first
    end

    def text_after(anchor)
      content.partition(anchors[anchor]).last
    end

    def line_number_text
      format(' %3d ', line_in_file)
    end

    def locate_anchor(anchor)
      editor.locate_cursor! line_in_window, anchor_column(anchor)
    end

    def anchor_column(anchor)
      cached_line_content.index(anchors[anchor]) + 1
    end

    def line_in_window
      parsed_entry.line_in_window
    end

    def cached_line_content
      line_number_text + content
    end

    def parsed_entry
      esearch.output.find_entry(relative_path, line_in_file)
    end
  end

  AnchoredContext = Struct.new(:name, :name_anchors, :entries) do # rubocop:disable Lint/StructNewOverride
    def begin_line
      entries.first.line_in_window - 1
    end

    def end_line
      entries.last.line_in_window + 1
    end

    def content
      entries.map(&:content)
    end

    def name_anchor_column(anchor)
      name.index(name_anchors[anchor]) + 1
    end
  end

  def locate_anchor(location, anchor)
    if location[:ui] == :name
      editor.search_literal(ctx1.name_anchors[anchor], '\\%>2l')
    else
      ctx = contexts[ctx_index(location)]
      ctx.entries[entry_index(location)].locate_anchor(anchor)
    end
  end

  def anchor_column(anchor, location)
    ctx = contexts[ctx_index(location)]

    if location[:ui] == :name
      ctx.name_anchor_column(anchor)
    else
      ctx.entries[entry_index(location)].anchor_column(anchor)
    end
  end

  def anchor_char(anchor, location)
    ctx = contexts[ctx_index(location)]

    if location[:ui] == :name
      ctx.name_anchors[anchor]
    else
      ctx.entries[entry_index(location)].anchors[anchor]
    end
  end

  def delete_between_columns(entry, column1, column2)
    text = entry.cached_line_content
    from = [entry.line_number_text.length, column1 - 1].max
    to = [entry.line_number_text.length, column2 - 1].max
    text[from..to] = ''
    text
  end

  # Builds context like:
  #
  # a__b__c:
  #   1 d__e__f
  #   2 g__h__i
  #
  # where [_] belongs to fillers_alphabet and [a-i] belong to alphabet of
  # anchors. fillers_alphabet is used to add more convenience in testing both
  # automatically and manually.
  def build_context(alphabet, fillers_alphabet, entries_count: 4, anchored_word_width: 1)
    # TODO: too much duplication
    filler = fillers_alphabet.shift

    anchor_begin, anchor_middle, anchor_end = alphabet.shift(3).map { |c| c * anchored_word_width }
    name_anchors = {
      begin:  anchor_begin,
      middle: anchor_middle,
      end:    anchor_end,
    }
    name = "#{anchor_begin}#{filler * 2}#{anchor_middle}#{filler * 2}#{anchor_end}"

    entries = entries_count.times.map do |i|
      anchor_begin, anchor_middle, anchor_end = alphabet.shift(3).map { |c| c * anchored_word_width }
      anchors = {
        begin:  anchor_begin,
        middle: anchor_middle,
        end:    anchor_end,
      }

      content = "#{anchor_begin}#{filler * 2}#{anchor_middle}#{filler * 2}#{anchor_end}"

      AnchoredEntry.new(name, i, i + 1, content, anchors)
    end

    AnchoredContext.new(name, name_anchors, entries)
  end

  def entry_index(location)
    if location[:ctx] == :header
      0 # everything that belongs to header points to entry 0
    elsif location.key?(:entry)
      location[:entry] < 0 ? contexts[ctx_index(location)].entries.count + location[:entry] : location[:entry]
    elsif location[:ui] == :name
      0 # as ctx name point to entry 0
    elsif location[:ui] == :separator
      # as separators are after the last entry
      contexts[ctx_index(location)].entries.count
    else
      raise ArgumentError
    end
  end

  def ctx_index(location)
    case location[:ctx]
    when :header
      0 # everything that belongs to header points to ctx 0
    when Integer
      location[:ctx]
    else
      raise ArgumentError, location
    end
  end
end
# rubocop:enable Metrics/ModuleLength
