# frozen_string_literal: true

module Helpers::Vim
  extend RSpec::Matchers::DSL
  shared_context 'set options' do |**options|
    before do
      editor.command! <<~TEXT
        let g:save = #{VimlValue.dump(options.keys.zip(options.keys).to_h.transform_values { |v| var("&#{v}") })}

        #{options.map { |k, v| "let &#{k} = #{VimlValue.dump(v)}" }.join("\n")}
      TEXT
    end

    after do
      editor.command! <<~TEXT
        #{options.map { |k, _v| "let &#{k} = g:save.#{k}" }.join("\n")}
      TEXT
    end
  end
end
