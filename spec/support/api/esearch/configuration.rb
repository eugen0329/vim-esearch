# frozen_string_literal: true

class API::ESearch::Configuration
  include VimlValue::SerializationHelpers

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

  def submit!(overwrite: false)
    if overwrite
      dict = VimlValue.dump(staged_configuration)
      editor.command!("let g:esearch = #{dict}")
    else
      dict = VimlValue.dump(staged_configuration)
      editor.command!("if !exists('g:esearch') | "\
                      "let g:esearch = #{dict} | "\
                      'else | '\
                      "call extend(g:esearch, #{dict}) | "\
                      'endif')
    end
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
      editor.echo func('get', func('get', var('g:'), 'esearch', {}), 'adapter', func('esearch#opts#default_adapter'))
    end
  end

  def output
    cache.fetch('out') do
      editor.echo func('get', func('get', var('g:'), 'esearch', {}), 'out', 'g:esearch#defaults#out')
    end
  end
end
