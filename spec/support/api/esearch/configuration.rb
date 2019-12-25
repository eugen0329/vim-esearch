# frozen_string_literal: true

require 'active_support/cache/memory_store'

class API::ESearch::Configuration
  attr_reader :editor, :cache
  attr_writer :output

  def initialize(editor)
    @editor = editor
    @cache = ActiveSupport::Cache::MemoryStore.new
  end

  def configure!(options)
    cache.write_multi(options)

    dict = to_vim_dict(options)
    editor.command("if !exists('g:esearch') | "\
                     "let g:esearch = #{dict} | "\
                     'else | '\
                     "call extend(g:esearch, #{dict}) | "\
                     'endif')
  end

  def adapter_bin=(path)
    editor.command("let g:esearch#adapter##{adapter}#bin = '#{path}'")
  end

  def adapter
    editor.echo('get(get(g:, "esearch", {}), "adapter", esearch#opts#default_adapter())')
  end

  def output
    @output ||= cache.fetch(:out) do
      editor.echo('get(get(g:, "esearch", {}), "out", g:esearch#defaults#out)')
    end
  end

  private

  def to_vim_dict(options)
    pairs = options.map do |name, val|
      val = "'#{val}'" unless val.is_a? Numeric
      "'#{name}': #{val}"
    end
    "{#{pairs.join(',')}}"
  end
end
