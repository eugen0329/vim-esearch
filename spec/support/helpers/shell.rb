# frozen_string_literal: true

module Helpers::Shell
  def split(str)
    paths, metadata, error = editor.echo(func('esearch#shell#split', str))
    return :error if error != 0

    paths.zip(metadata).map do |path, m|
      [path, m['start']..m['end']]
    end
  end

  def wildcards_at(str)
    _paths, metadata, error = editor.echo(func('esearch#shell#split', str))
    return :error if error != 0

    metadata.map { |word| word['wildcards'] }
  end

  def split_and_escape(str)
    paths, metadata, error = editor.echo(func('esearch#shell#split', str))
    return :error if error != 0

    paths.zip(metadata).map do |path, meta|
      editor.echo(func('esearch#shell#fnameescape', path, meta))
    end
  end
end
