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
    staged_configuration.deep_merge!(options.deep_symbolize_keys)
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

  def qr
    editor.echo var('g:esearch#unicode#quote_right')
  end

  def ql
    editor.echo var('g:esearch#unicode#quote_left')
  end

  def win_map
    staged_configuration['win_map'] ||= []
  end

  def configure!(options)
    configure(options)
    submit!(overwrite: true)
  end

  def adapter_bin=(path)
    staged_configuration.deep_merge!({adapters: {adapter => {bin: path.to_s}}}.deep_symbolize_keys)
  end

  def adapter
    cache.fetch('adapter') do
      editor.echo func('get', func('get', var('g:'), 'esearch', {}), 'adapter', func('esearch#config#default_adapter'))
    end
  end

  def output
    # cache.fetch('out') do
    editor.echo func('get', func('get', var('g:'), 'esearch', {}), 'out', 'win')
    # end
  end
end
