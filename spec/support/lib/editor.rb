# frozen_string_literal: true

require 'active_support/core_ext/class/attribute'
require 'active_support/notifications'

# rubocop:disable Layout/ClassLength
class Editor
  include API::Mixins::Throttling
  include API::Mixins::BecomeTruthyWithinTimeout

  class MissingBufferError < RuntimeError; end

  KEEP_VERTICAL_POSITION = KEEP_HORIZONTAL_POSITION = 0
  CLIPBOARD_REGISTER = '"'

  class_attribute :cache_enabled, default: true
  class_attribute :throttle_interval, default: Configuration.editor_throttle_interval
  class_attribute :reader_class, default: Editor::Read::Batched
  attr_reader :vim_client_getter, :reader

  delegate :cached?, :evaluated?, :with_ignore_cache, :handle_state_change!, :var, :func, to: :reader

  def initialize(vim_client_getter, **kwargs)
    @cache_enabled = kwargs.fetch(:cache_enabled) { self.class.cache_enabled }
    @vim_client_getter = vim_client_getter
    @reader = kwargs.fetch(:reader) do
      self.class.reader_class.new(vim_client_getter, @cache_enabled)
    end
  end

  MODES = {
    'n' => :normal,
    'c' => :commandline
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

  def lines(range = nil, prefetch_count: 30)
    raise ArgumentError unless prefetch_count.positive?
    return enum_for(:lines, range, prefetch_count: prefetch_count) { lines_count } unless block_given?

    from, to = lines_range(range)
    current_lines_count = lines_count

    from.step(to, prefetch_count).each do |prefetch_from|
      break if evaluated?(current_lines_count) && current_lines_count < prefetch_from

      prefetch_to = [to || Float::INFINITY, prefetch_from + prefetch_count - 1].min
      lines_array(prefetch_from..prefetch_to)
        .each { |line_content| yield(line_content) }
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

  def lines_array(range = nil)
    from, to = lines_range(range)
    to = func('line', '$') if to.nil?

    echo func('getline', from, to)
  end

  def lines_count
    echo func('line', '$')
  end

  def cd!(where)
    press! ":cd #{where}<Enter>"
  end

  def bufname(arg)
    echo func('bufname', arg)
  end

  def matches_for(group)
    echo func('Matches', group)
  end

  def current_buffer_name
    bufname('%')
  end

  def current_line_number
    echo func('line', '.')
  end

  def search_literal(text, modifiers = '')
    echo(func('search', modifiers + text.gsub(/([$^~.*\[\]\\])/, '\\\\\1'), 'w'))
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

  def edit!(filename)
    command!("edit! #{filename}")
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

  def buffers
    editor
      .ls
      .split("\n")
      .map { |l| l.scan(/\s+([\w\d%#\s]*?)\s+\+?\s*"(.*)"/)[0][1] }
  end

  def locate_buffer!(name)
    location = with_ignore_cache do
      echo(func('esearch#util#bufloc', func('bufnr', '^' + name)))
    end

    raise MissingBufferError if location.blank?

    editor.command! <<~VIML
      tabn #{location[0]}
      #{location[1]} winc w
    VIML
  end

  # TODO: better name
  def ls(include_unlisted: true)
    return command('ls!') if include_unlisted

    command('ls')
  end

  def delete_all_buffers_and_clear_messages_and_reset_input_and_do_too_much!
    # TODO: fix after modifier implementation
    command <<~CLEANUP_COMMANDS
      %bwipeout!
      messages clear
      call feedkeys(\"\\<Esc>\\<Esc>\\<C-\\>\\<C-n>\", \"n\")
      let @#{CLIPBOARD_REGISTER} = ''
      set lines=22
    CLEANUP_COMMANDS
  end

  def close_current_window!
    command!('tabnew | %bwipeout!')
  end

  def cleanup!
    delete_all_buffers_and_clear_messages_and_reset_input_and_do_too_much!
    handle_state_change!
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
    # NOTE that $ works for line_number by default but doesn't work for col
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

  def trigger_cursor_moved_event!
    press!('<Esc>lh')
  end

  def command(string_to_execute)
    # vim.command("doau CmdlineEnter | #{string_to_execute} | doau CmdlineLeave")
    vim.command(string_to_execute)
  end

  def command!(string_to_execute)
    handle_state_change!

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
    handle_state_change!

    instrument(:press, data: keyboard_keys) do
      throttle(:state_modifying_interactions, interval: throttle_interval) do
        vim.normal(keyboard_keys)
      end
    end
  end

  def press_with_user_mappings!(*keyboard_keys, split_undo_entry: true)
    handle_state_change!

    instrument(:press_with_user_mappings!, data: keyboard_keys) do
      throttle(:state_modifying_interactions, interval: throttle_interval) do
        # from :h undojoin
        # Setting the value of 'undolevels' also breaks undo entry.  Even when the new value
        # is equal to the old value.
        editor.command('let &undolevels=&undolevels') if split_undo_entry
        vim.feedkeys keyboard_keys_to_string(*keyboard_keys)
      end
    end
  end

  alias send_keys press_with_user_mappings! # to resemble capybara interace

  # is required as far as continious sequence may be handled incorrectly by vim
  def send_keys_separately(*keyboard_keys)
    editor.command('let &undolevels=&undolevels')
    keyboard_keys.map { |key| send_keys(key, split_undo_entry: false) }
  end

  # imitation of command inputter by a user
  def send_command(string_to_execute)
    command! <<~VIML
      call histadd(":", #{VimlValue.dump(string_to_execute)})
    VIML

    history_updated = with_ignore_cache do
      became_truthy_within?(5.seconds) do
        editor.echo(func('histget', ':', -1)) == string_to_execute
      end
    end
    raise unless history_updated

    editor.command('let &undolevels=&undolevels')
    press! ":#{string_to_execute}<Enter>"
  end

  def raw_echo(arg)
    vim.echo(arg)
  end

  def echo(arg)
    reader.echo arg
  end

  def clipboard=(content)
    editor.command "let @#{CLIPBOARD_REGISTER} = \"#{content}\""
  end

  private

  SYMBOL_TO_KEYBOARD_KEY = {
    enter:     '\\<Cr>',
    left:      '\\<Left>',
    right:     '\\<Right>',
    delete:    '\\<Del>',
    leader:    '\\\\',
    backspace: '\\<Bs>',
    space:     '\\<Space>',
    escape:    '\\<Esc>',
    up:        '\\<Up>',
    down:      '\\<Down>',
    end:       '\\<End>',
    paste:     "\\<C-r>\\<C-o>#{CLIPBOARD_REGISTER}"
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

  def instrument(operation, options = {})
    options.merge!(operation: operation)
    ActiveSupport::Notifications.instrument("editor.#{operation}", options) { yield }
  end

  def vim
    vim_client_getter.call
  end
end
# rubocop:enable Layout/ClassLength
