# frozen_string_literal: true

module Helpers::Modifiable::Linewise
  def entries_from_range(from, to)
    from_ctx = ctx_index(from)
    to_ctx = ctx_index(to)
    from_entry = entry_index(from)
    to_entry = entry_index(to)

    return contexts[from_ctx].entries[from_entry..to_entry] if from_ctx == to_ctx

    top_ctx_entries = contexts[from_ctx].entries[from_entry..]
    entries_of_ctxs_between =
      contexts[from_ctx + 1..to_ctx - 1].map(&:entries).flatten
    bottom_ctx_entries =
      if to[:ui] == :name
        []
      else
        contexts[to_ctx].entries[..to_entry]
      end

    top_ctx_entries + entries_of_ctxs_between + bottom_ctx_entries
  end

  # Called line_in_window as there are 2 kinds of line numbers: line_in_window
  # (offset from to top) and line_in_file (line, rendered within LineNr virtual
  # interface)
  def line_in_window(location)
    if location[:ctx] == :header
      header_line_in_window(location)
    else
      regular_context_line_in_window(location)
    end
  end

  def header_line_in_window(location)
    if location[:ui] == :name
      1
    elsif location[:ui] == :separator
      2
    else
      raise ArgumentError
    end
  end

  def regular_context_line_in_window(location)
    ctx = contexts[location[:ctx]]

    if location[:entry]
      ctx.entries[location[:entry]].line_in_window
    elsif location[:ui] == :separator
      ctx.entries[-1].line_in_window + 1
    elsif location[:ui] == :name
      ctx.entries[0].line_in_window - 1
    else
      raise ArgumentError
    end
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
    if location[:ctx] == :header
      0 # everything that belongs to header points to ctx 0
    elsif location[:ctx].is_a? Integer
      location[:ctx]
    else
      raise ArgumentError, location
    end
  end
end
