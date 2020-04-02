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

  def global
    editor.echo func('get', var('g:'), 'esearch', {})
  end

  def configure(options)
    cache.write_multi(options)
    staged_configuration.merge!(options)
  end

  # TODO: a hack that should be rewrited in future
  def submit!(overwrite: true)
    dict = VimlValue.dump(staged_configuration)

    if overwrite
      editor.command!("let g:esearch = #{dict}")
    else
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
    submit!(overwrite: true)
  end

  def adapter_bin=(path)
    # TODO: configuration
    editor.command! <<~VIML
      call esearch#opts#init_lazy_global_config()
      call extend(g:esearch.adapters, {#{adapter.dump}: {}}, 'keep')
      call extend(g:esearch.adapters[#{adapter.dump}], {'bin': '#{path}'})
    VIML
  end

  def adapter
    cache.fetch('adapter') do
      editor.echo func('get', func('get', var('g:'), 'esearch', {}), 'adapter', func('esearch#opts#default_adapter'))
    end
  end

  def output
    cache.fetch('out') do
      editor.echo func('get', func('get', var('g:'), 'esearch', {}), 'out', var('g:esearch#defaults#out'))
    end
  end
end
