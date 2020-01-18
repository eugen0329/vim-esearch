# frozen_string_literal: true

class API::ESearch::Configuration
  include API::Mixins::VimTypes

  attr_reader :editor, :cache, :staged_configuration
  attr_writer :output

  def initialize(editor)
    @editor = editor
    @cache = CacheStore.new

    @staged_configuration = {}
  end

  def configure(options)
    cache.write_multi(options)
    staged_configuration.merge!(options)
  end

  def submit!
    dict = to_vim_dict(staged_configuration)
    editor.command!("if !exists('g:esearch') | "\
                     "let g:esearch = #{dict} | "\
                     'else | '\
                     "call extend(g:esearch, #{dict}) | "\
                     'endif')
    staged_configuration.clear
  end

  def configure!(options)
    configure(options)
    submit!
  end

  def adapter_bin=(path)
    editor.command!("let g:esearch#adapter##{adapter}#bin = '#{path}'")
  end

  def adapter
    cache.fetch('adapter') do
      editor.raw_echo('get(get(g:, "esearch", {}), "adapter", esearch#opts#default_adapter())')
    end
  end

  def output
    cache.fetch('out') do
      editor.raw_echo('get(get(g:, "esearch", {}), "out", g:esearch#defaults#out)')
    end
  end
end
