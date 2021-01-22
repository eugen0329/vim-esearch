# frozen_string_literal: true

require 'active_support/core_ext/class/attribute'
require 'active_support/notifications'

# rubocop:disable Metrics/ClassLength
class Editor
  include API::Mixins::Throttling
  include API::Mixins::BecomeTruthyWithinTimeout

  class MissingBufferError < RuntimeError; end

  KEEP_VERTICAL_POSITION = KEEP_HORIZONTAL_POSITION = 0
  CLIPBOARD_REGISTER = '"'
  CURRENT_BUFFER = '%'

  class_attribute :cache_enabled, default: true
  class_attribute :throttle_interval, default: Configuration.editor_throttle_interval
  class_attribute :reader_class, default: Editor::Read::Batched
  attr_reader :vim_client_getter, :reader

  delegate :cached?, :evaluated?, :with_ignore_cache, :invalidate_cache!, :var, :func, to: :reader

  def initialize(**kwargs)
    @vim_client_getter =
      if Configuration.debug_specs_performance?
        -> { VimrunnerSpy.new(Configuration.vim) }
      else
        Configuration.method(:vim)
      end

    @cache_enabled = kwargs.fetch(:cache_enabled) { self.class.cache_enabled }
    @reader = kwargs.fetch(:reader) do
      self.class.reader_class.new(vim_client_getter, @cache_enabled)
    end
  end

  MODES = {
    'n'    => :normal,
    'no'   => :operator_pending,
    'c'    => :commandline,
    'i'    => :insert,
    'v'    => :visual,
    'V'    => :linewise_visual,
    "\x16" => :blockwise_visual,
  }.freeze

  def mode
    MODES[echo(func('mode'))]
  end

  def autocommands_listed_in_manual
    command! 'help au'
    lines(prefetch_count: 100)
      .select { |l| l.start_with?('|') }
      .map { |l| l.scan(/^\|(\w+)\|/)[0] }
      .compact
      .map(&:first)
  end

  def line(number)
    echo func('getline', number)
  end

  def lines(range = nil, buffer: CURRENT_BUFFER, prefetch_count: 30, &block)
    raise ArgumentError unless prefetch_count.positive?
    return enum_for(:lines, range, prefetch_count: prefetch_count) { lines_count } unless block_given?

    from, to = lines_range(range)
    current_lines_count = lines_count

    from.step(to, prefetch_count).each do |prefetch_from|
      break if evaluated?(current_lines_count) && current_lines_count < prefetch_from

      prefetch_to = [to || Float::INFINITY, prefetch_from + prefetch_count - 1].min
      lines_array(prefetch_from..prefetch_to, buffer: buffer)
        .each(&block)
    end
  end

  def errors
    echo var('v:errors')
  end

  def location
    echo([func('line', '.'), func('col', '.')])
  end

  def current_line
    echo func('line', '.')
  end

  def lines_array(range = nil, buffer: CURRENT_BUFFER)
    from, to = lines_range(range)
    to = func('line', '$') if to.nil?
    echo func('getbufline', buffer, from, to)
  end

  def lines_count
    echo func('line', '$')
  end

  def cd!(where)
    press! ":cd #{where}<enter>"
  end

  def bufname(arg = '')
    echo func('bufname', arg)
  end

  def matches_for(group)
    echo func('Matches', group)
  end

  def expand(expr)
    echo func('expand', expr)
  end

  def current_buffer_name
    expand('%:p')
  end

  def current_buffer_basename
    expand('%:t')
  end

  def current_line_number
    echo func('line', '.')
  end

  def search_literal(text, modifiers = '')
    echo(func('search', modifiers + escape_regexp(text), 'w'))
  end

  # using vim builtin rules
  def escape_filename(text)
    # NOTE: only leading [+>] are escaped (according to builtin :h fnameescape).
    # [-] is escaped when it's the only char in a name (to prevent confusion
    # with `cd -` argument)
    text
      .to_s
      .gsub(/([\t\n *%$'"<{\[\\])/, '\\\\\1')
      .sub(/^([+>])/, '\\\\\1')
      .sub(/^-$/, '\\-')
  end

  def escape_regexp(text)
    text.gsub(/([$^~.*\[\]\\])/, '\\\\\1')
  end

  def syntax_aliases_at(location_regexps)
    echo func('CollectSyntaxAliases', location_regexps)
  end

  def current_column_number
    echo func('col', '.')
  end

  def changenr
    echo(func('changenr'))
  end

  def open_buffer!(filename)
    command!("buffer #{filename}")
  end

  def quit!
    command! 'quit'
  end

  def syntax_under_cursor
    echo(func('SynStack'))
  end

  def edit_ignoring_swap!(filename, opener: 'edit!')
    raw_send_keys "\e\e\e:#{opener} #{escape_filename(filename)}\n"
    raw_send_keys 'e' # to bypass the swap prompt
  end

  def edit!(filename)
    command!("edit! #{escape_filename(filename)}")
  end

  def pwd
    command('pwd')
  end

  def close!
    command!('close!')
  end

  def tabs
    command('tabs')
      .split("\n")
      .select { |l| l =~ /^Tab page/ }
      .map { |l| l.scan(/^Tab page (\d)/)[0][0] }
  end

  def buffer_numbers
    ls
      .split("\n")
      .map { |line| line.scan(/\A\s+\d+/) }
      .flatten
      .map(&:to_i)
  end

  # TODO: extract to buffer class
  def buffer_variable(number, name)
    echo func('getbufvar', number, name)
  end

  # TODO: extract to Window class
  def window_variable(number, name)
    echo func('getwinvar', number, name)
  end

  def jumps
    command('jumps').split("\n")
  end

  def buffers
    ls
      .split("\n")
      .map { |line| line.scan(/\A\s+([\w\d%#=\s]*?)\s+\+?\s*"(.*)"/)[0][1] }
      .map { |path| Pathname(path).cleanpath.expand_path.to_s }
  end

  def bufnr
    echo func('bufnr')
  end

  # TODO: better name
  def ls(include_unlisted: true)
    return command('ls!') if include_unlisted

    command('ls')
  end

  def delete_all_buffers_and_clear_messages_and_reset_input_and_do_too_much!
    # TODO: fix after modifier implementation
    command <<~CLEANUP_COMMANDS
      tabnew
      %bwipeout!
      messages clear
      call feedkeys(\"\\<esc>\\<esc>\", \"n\")
      let @#{CLIPBOARD_REGISTER} = ''
      set lines=22
    CLEANUP_COMMANDS
  end

  def close_current_window!
    command!('tabnew | %bwipeout!')
  end

  def messages
    # E325 - messages about existing swaps, not relevant and can be skipped
    reader
      .echo(func('execute', 'messages'))
      .split("\n")
      .reject { |message| message.include?('E325:') || message.blank? || message.include?('DEPRECATION:') }
  end

  def split!(path)
    command! "split #{escape_filename(path)}"
  end

  def tabedit!(path)
    command! "tabedit #{escape_filename(path)}"
  end

  def bwipeout(buffer_number)
    command!("bwipeout #{buffer_number}")
  end

  def bdelete(buffer_number)
    command!("bwipeout #{buffer_number}")
  end

  def cleanup!
    delete_all_buffers_and_clear_messages_and_reset_input_and_do_too_much!
    invalidate_cache!
  end

  def bufdelete!(ignore_unsaved_changes: false)
    return command!('bdelete!') if ignore_unsaved_changes

    command!('bdelete')
  end
  alias delete_current_buffer! bufdelete!

  def locate_line!(line_number)
    locate_cursor! line_number, KEEP_HORIZONTAL_POSITION
  end

  def locate_column!(column_number)
    locate_cursor! KEEP_VERTICAL_POSITION, column_number
  end

  def locate_cursor!(line_number, column_number)
    # NOTE: that $ works for line_number by default but doesn't work for col
    column_number = func('col', '$') if column_number == '$'
    command!("call #{VimlValue.dump(func('cursor', line_number, column_number))} | doau CursorMoved").to_i == 0
  end

  def modified?
    echo(var('&modified')) == 1
  end

  def filetype
    echo var('&ft')
  end

  def quickfix_window_name
    echo func('get', var('w:'), 'quickfix_title', '')
  end

  def cwd
    echo func('getcwd')
  end

  def command(string_to_execute)
    # vim.command("doau CmdlineEnter | #{string_to_execute} | doau CmdlineLeave")
    vim.command(string_to_execute)
  end

  def command!(string_to_execute)
    invalidate_cache!

    instrument(:command!, data: string_to_execute) do
      throttle(:state_modifying_interactions, interval: throttle_interval) do
        command(string_to_execute)
      end
    end
  end

  def commandline_cursor_location
    echo func('getcmdpos')
  end

  def commandline_content
    echo func('getcmdline')
  end

  def press!(keyboard_keys)
    invalidate_cache!

    instrument(:press, data: keyboard_keys) do
      throttle(:state_modifying_interactions, interval: throttle_interval) do
        vim.normal(keyboard_keys)
      end
    end
  end

  def press_with_user_mappings!(*keyboard_keys, split_undo_entry: true)
    invalidate_cache!

    instrument(:press_with_user_mappings!, data: keyboard_keys) do
      throttle(:state_modifying_interactions, interval: throttle_interval) do
        # from :h undojoin
        # Setting the value of 'undolevels' also breaks undo entry.  Even when the new value
        # is equal to the old value.
        command('let &undolevels=&undolevels') if split_undo_entry
        vim.feedkeys keyboard_keys_to_string(*keyboard_keys)
      end
    end
  end

  alias send_keys press_with_user_mappings! # to resemble capybara interace

  # is required as far as continious sequence may be handled incorrectly by vim
  def send_keys_separately(*keyboard_keys)
    command('let &undolevels=&undolevels')
    keyboard_keys.map { |key| send_keys(key, split_undo_entry: false) }
  end

  # Allows interfacing with prompts etc. where other functions doesn't work
  def raw_send_keys(*keys)
    invalidate_cache!
    keys.each { |key| vim.type(key) }
  end

  # imitation of command inputter by a user
  def send_command(string_to_execute)
    command! <<~VIML
      call histadd(":", #{VimlValue.dump(string_to_execute)})
    VIML

    history_updated = with_ignore_cache do
      became_truthy_within?(5.seconds) do
        echo(func('histget', ':', -1)) == string_to_execute
      end
    end
    raise unless history_updated

    command('let &undolevels=&undolevels')
    press! ":#{string_to_execute}"
    send_keys :enter
  end

  def raw_echo(arg)
    vim.echo(arg)
  end

  def echo(arg)
    reader.echo arg
  end

  def echo!(arg)
    invalidate_cache!
    reader.echo(arg)
  end

  def clipboard=(content)
    command "let @#{CLIPBOARD_REGISTER} = \"#{content}\""
  end

  private

  SYMBOL_TO_KEYBOARD_KEY = {
    enter:     '\\<Cr>',
    left:      '\\<left>',
    right:     '\\<right>',
    delete:    '\\<Del>',
    leader:    '\\\\',
    backspace: '\\<bs>',
    space:     '\\<space>',
    escape:    '\\<esc>',
    up:        '\\<up>',
    down:      '\\<down>',
    end:       '\\<End>',
    paste:     "\\<c-r>\\<c-o>#{CLIPBOARD_REGISTER}",
    control_c: '\\<c-c>',
    control_w: '\\<c-w>',
  }.freeze

  def keyboard_keys_to_string(*keyboard_keys)
    keyboard_keys.compact.map do |key|
      if key.is_a? Symbol
        SYMBOL_TO_KEYBOARD_KEY.fetch(key)
      else
        key
      end
    end.join
  end

  def lines_range(range)
    return [1, nil] if range.blank?

    raise ArgumentError if range.begin.present? && range.begin < 1

    from = [range.begin, 1].compact.max
    to = range.end
    raise ArgumentError if to.present? && from > to

    [from, to]
  end

  def instrument(operation, options = {}, &block)
    options.merge!(operation: operation)
    ActiveSupport::Notifications.instrument("editor.#{operation}", options, &block)
  end

  def vim
    vim_client_getter.call
  end
end
# rubocop:enable Metrics/ClassLength
