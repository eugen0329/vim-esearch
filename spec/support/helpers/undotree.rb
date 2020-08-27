# frozen_string_literal: true

module Helpers::Undotree
  extend RSpec::Matchers::DSL

  def undotree_nodes
    collector = lambda do |entries|
      entries.map { |e| e['seq'] } + entries.map { |e| e['alt'] }.compact.map(&collector)
    end

    collector.call(editor.echo(var('undotree().entries'))).flatten
  end

  def esearch_undotree_nodes
    editor.echo(var('keys(b:esearch.undotree.nodes)')).map(&:to_i)
  end
end
