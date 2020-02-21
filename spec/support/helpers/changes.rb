# frozen_string_literal: true

module Helpers::Changes
  extend RSpec::Matchers::DSL

  def unknown
    -1
  end

  shared_context 'setup clever-f testing' do |**_options|
    after do
      editor.command! <<~TEXT
        call clever_f#reset()
      TEXT
    end
  end

  shared_context 'set options' do |**options|
    before do
      res = editor.command! <<~TEXT
        let g:save = #{VimlValue.dump(options.keys.zip(options.keys).to_h.transform_values { |v| var("&#{v}") })}

        #{options.map { |k, v| "let &#{k} = #{VimlValue.dump(v)}" }.join("\n")}
      TEXT
    end

    after do
      res = editor.command! <<~TEXT
        #{options.map { |k, _v| "let &#{k} = g:save.#{k}" }.join("\n")}
      TEXT
    end
  end

  matcher :include_payload do |id, from, to|
    diffable

    attr_reader :expected

    match do |event|
      @expected = {
        'id'    => id,
        'line1' => from.begin,
        'line2' => to.begin,
        'col1'  => from.end,
        'col2'  => to.end
      }.compact
      @actual = event.slice(*@expected.keys)

      values_match?(@expected, @actual)
    end
  end
end
