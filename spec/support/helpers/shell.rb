# frozen_string_literal: true

module Helpers::Shell
  def split(str)
    paths, error = editor.echo(func('esearch#shell#split', str))
    return :error if error != 0

    paths.map do |path|
      [path['str'], path['begin']..path['end']]
    end
  end

  def metachars_at(str)
    paths, error = editor.echo(func('esearch#shell#split', str))
    return :error if error != 0

    paths.map { |word| word['metachars'] }
  end

  def split_and_escape(str)
    paths, error = editor.echo(func('esearch#shell#split', str))
    return :error if error != 0

    paths.map do |path|
      editor.echo(func('esearch#shell#escape', path))
    end
  end
end
