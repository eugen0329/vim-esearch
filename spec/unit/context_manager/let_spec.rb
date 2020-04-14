# frozen_string_literal: true

require 'spec_helper'

describe 'esearch#option' do
  include VimlValue::SerializationHelpers
  include Helpers::Vim

  around { |e| editor.with_ignore_cache(&e) }

  describe 'esearch#context_manager#let#do' do
    let(:original_variables) do
      {
        'b:int_var'    => 11,
        'w:int_var'    => 12,
        't:int_var'    => 13,
        'g:int_var'    => 14,
        'b:float_var'  => 11.0,
        'w:float_var'  => 12.0,
        't:float_var'  => 13.0,
        'g:float_var'  => 14.0,
        'b:string_var' => '11',
        'w:string_var' => '12',
        't:string_var' => '13',
        'g:string_var' => '14',
        '&directory'   => '1-option',
        '$GLOBAL_VAR'  => '1-GLOBAL_VAR',
        '@/'           => '1-register1',
        '@='           => '1-register2',
      }
    end
    let(:updated_variables) do
      {
        'b:int_var'    => 21,
        'w:int_var'    => 22,
        't:int_var'    => 23,
        'g:int_var'    => 24,
        'b:float_var'  => 21.0,
        'w:float_var'  => 22.0,
        't:float_var'  => 23.0,
        'g:float_var'  => 24.0,
        'b:string_var' => '21',
        'w:string_var' => '22',
        't:string_var' => '23',
        'g:string_var' => '24',
        '&directory'   => '2-option',
        '$GLOBAL_VAR'  => '2-GLOBAL_VAR',
        '@/'           => '2-register1',
        '@='           => '2-register2',
      }
    end
    let(:variables) { original_variables.keys.map { |k| var(k) } }

    subject(:manager_enter) do
      lambda do |assignments|
        editor.command! <<~VIML
          let g:variables = #{VimlValue.dump(func('esearch#let#restorable', assignments))}
        VIML
      end
    end

    before do
      editor.command! original_variables
        .map { |k, v| "let #{k} = #{v.inspect}" }.join("\n")
    end

    describe '#restorable' do
      it 'sets variables on enter' do
        expect { manager_enter.call(updated_variables) }
          .to change { editor.echo(variables) }
          .from(original_variables.values)
          .to(updated_variables.values)
      end
    end

    describe '.restore' do
      subject(:manager_exit) do
        -> { editor.echo(func('g:variables.restore')) }
      end

      before { manager_enter.call(updated_variables) }

      it 'resets variables to original values on exit' do
        expect { manager_exit.call }
          .to change { editor.echo(variables) }
          .from(updated_variables.values)
          .to(original_variables.values)
      end
    end
  end
end
