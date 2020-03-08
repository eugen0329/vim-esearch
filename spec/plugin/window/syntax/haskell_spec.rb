# frozen_string_literal: true

require 'spec_helper'
require_relative 'setup_syntax_testing_shared_context'

describe 'esearch window context syntax', :window do
  include Helpers::FileSystem
  include Helpers::WindowSyntaxContext

  describe 'haskell' do
    # blank line is kept intentionally to know whether the last verified line
    # corrupts LineNr virtual UI or not

    let(:source_file_content) do
      <<~SOURCE
      import qualified Some.Module as m
      import qualified Some.Module hiding (x,y)
      module
      infix
      infixl
      infixr
      class
      data
      deriving
      instance
      default
      where
      type
      newtype
      do
      case
      of
      let
      in
      if
      then
      else
      undefined
      error
      trace
      "es_hsString"
      "es_hsString\\"
      "es_hsString
      'c'

      -- es_hsLineComment
      --es_hsLineComment
      {-es_hsBlockComment-}
      {- es_hsBlockComment -}
      {-es_hsBlockComment
      {- es_hsBlockComment
      {-#es_hsPragma#-}
      {-# es_hsPragma #-}
      {-#es_hsPragma
      {-# es_hsPragma

      SOURCE
    end
    let(:source_file) { file(source_file_content, 'main.hs') }

    include_context 'setup syntax testing'

    # 1. Verification is done in a single example for performance reasons (as
    # vim's +clientserver is too sluggish; it doesn't affect debuggability as
    # the matcher is diffable)
    # 2. Lines that can cause matching across line end (e.g. not terminated strings
    # or comments) are not groupped and scattered across source_file to cause as
    # more potential errors as possible
    it do
      is_expected.to have_highligh_aliases(
        word('as')                        => %w[es_hsImportMod Include],
        word('qualified')                 => %w[es_hsImportMod Include],
        word('hiding')                    => %w[es_hsImportMod Include],
        word('infix')                     => %w[es_hsInfix PreProc],
        word('infixl')                    => %w[es_hsInfix PreProc],
        word('infixr')                    => %w[es_hsInfix PreProc],
        word('class')                     => %w[es_hsStructure Structure],
        word('data')                      => %w[es_hsStructure Structure],
        word('deriving')                  => %w[es_hsStructure Structure],
        word('instance')                  => %w[es_hsStructure Structure],
        word('default')                   => %w[es_hsStructure Structure],
        word('where')                     => %w[es_hsStructure Structure],
        word('type')                      => %w[es_hsTypedef Typedef],
        word('newtype')                   => %w[es_hsTypedef Typedef],
        word('do')                        => %w[es_hsStatement Statement],
        word('case')                      => %w[es_hsStatement Statement],
        word('of')                        => %w[es_hsStatement Statement],
        word('let')                       => %w[es_hsStatement Statement],
        word('in')                        => %w[es_hsStatement Statement],
        word('if')                        => %w[es_hsConditional Conditional],
        word('then')                      => %w[es_hsConditional Conditional],
        word('else')                      => %w[es_hsConditional Conditional],
        word('undefined')                 => %w[es_hsDebug Debug],
        word('error')                    => %w[es_hsDebug Debug],
        word('trace')                     => %w[es_hsDebug Debug],
        word('import')                    => %w[es_hsImport Include],
        word('import')                    => %w[es_hsImport Include],
        word('module')                    => %w[es_hsModule Structure],
        region('"es_hsString"')           => %w[es_hsString String],
        region('"es_hsString\\\\"')       => %w[es_hsString String],
        region('"es_hsString')            => %w[es_hsString String],
        region("'c'")                     => %w[es_hsCharacter Character],
        region('--es_hsLineComment')      => %w[es_hsLineComment Comment],
        region('-- es_hsLineComment')     => %w[es_hsLineComment Comment],
        region('{-es_hsBlockComment-}')   => %w[es_hsBlockComment Comment],
        region('{- es_hsBlockComment -}') => %w[es_hsBlockComment Comment],
        region('{-es_hsBlockComment')     => %w[es_hsBlockComment Comment],
        region('{- es_hsBlockComment')    => %w[es_hsBlockComment Comment],
        region('{-#es_hsPragma#-}')       => %w[es_hsPragma SpecialComment],
        region('{-# es_hsPragma #-}')     => %w[es_hsPragma SpecialComment],
        region('{-#es_hsPragma')          => %w[es_hsPragma SpecialComment],
        region('{-# es_hsPragma')         => %w[es_hsPragma SpecialComment],
      )
    end
  end
end

