# frozen_string_literal: true

class API::ESearch::Configuration
  attr_reader :spec, :editor

  def initialize(spec, editor)
    @spec = spec
    @editor = editor
  end

  def configure!(options)
    dict = to_vim_dict(options)
    spec.vim.command("if !exists('g:esearch') | "\
                     "let g:esearch = #{dict} | "\
                     'else | '\
                     "call extend(g:esearch, #{dict}) | "\
                     'endif')
  end

  def adapter_bin=(path)
    spec.vim.command("let g:esearch#adapter##{adapter}#bin = '#{path}'")
  end

  def adapter
    spec.vim.echo('get(get(g:, "esearch", {}), "adapter", esearch#opts#default_adapter())')
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
