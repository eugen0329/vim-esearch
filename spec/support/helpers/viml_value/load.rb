# frozen_string_literal: true

module Helpers::VimlValue::Load
  extend ActiveSupport::Concern
  extend Helpers::VimlValue::DefineSharedMatchers

  # Pretty ugly way to reduce duplication (other approaches involve even
  # more problems mostly tied with implicit dependencies)
  define_action_matcher!(:be_loaded_as, 'load') { VimlValue.load(actual) }
  define_raise_on_action_matcher!(:raise_on_load, 'loading') { VimlValue.load(actual) }

  included do
    def self.function(name)
      VimlValue::Visitors::ToRuby::Funcref.new(name)
    end
  end

  def function(name)
    VimlValue::Visitors::ToRuby::Funcref.new(name)
  end

  def dict_recursive_ref
    VimlValue::Visitors::ToRuby::DictRecursiveRef
  end

  def list_recursive_ref
    VimlValue::Visitors::ToRuby::ListRecursiveRef
  end
end
