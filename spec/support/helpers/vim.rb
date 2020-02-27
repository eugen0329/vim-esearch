# frozen_string_literal: true

module Helpers::Vim
  extend RSpec::Matchers::DSL
  include VimlValue::SerializationHelpers

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

  # TODO: fix reusability
  matcher :change_option do |option, timeout: 1|
    include API::Mixins::BecomeTruthyWithinTimeout

    supports_block_expectations

    match do |block|
      editor.with_ignore_cache do
        @before = editor.echo(var(option))
        block.call

        @changed = became_truthy_within?(timeout) do
          @after = editor.echo(var(option))
          @before != @after
        end
        return false unless @changed

        if @to
          @changed_to_expected = became_truthy_within?(timeout) do
            @after = editor.echo(var(option))
            values_match?(@to, @after)
          end
          return false unless @changed_to_expected
        end
      end

      true
    end

    chain :to do |to|
      @to = to
    end

    failure_message do
      msg = "expected to change #{@before.inspect}"
      msg += " to #{@to.inspect}, got #{@after.inspect}" if @to
      msg
    end
  end
end
