# frozen_string_literal: true

require 'spec_helper'

describe 'esearch#buf' do
  include Helpers::FileSystem
  include VimlValue::SerializationHelpers

  # TODO: character properties (\p{Alnum} etc.)
  describe 'esearch#buf#find' do
    context 'when filename contains special characters' do
      subject(:convert) do
        lambda do |input|
          editor.echo(func('esearch#regex#pcre2vim#convert', input))
        end
      end

      # TODO: ESCAPED CHARACTERS
      # https://www.pcre.org/current/doc/html/pcre2syntax.html#SEC3

      describe 'class []' do
        # https://www.pcre.org/current/doc/html/pcre2syntax.html#SEC8
        it { expect(convert.call('[]')).to   eq('[]') }
        it { expect(convert.call('[\[]')).to eq('[\[]') }
        it { expect(convert.call('[\]]')).to eq('[\]]') }
        it { expect(convert.call('[a]')).to eq('[a]') }
        it { expect(convert.call('[^a]')).to eq('[^a]') }
        it { expect(convert.call('[a-z]')).to eq('[a-z]') }
        it { expect(convert.call('[*+|]')).to eq('[*+|]') }

        context 'when metachars are inside' do
          describe 'regular escapes' do
            it { expect(convert.call('[\s]')).to eq('[ \t]') } # \r\n\f\v are ignored
            it { expect(convert.call('[\w]')).to eq('[0-9a-zA-Z_]') }
            it { expect(convert.call('[\d]')).to eq('[0-9]') }
            it { expect(convert.call('[\h]')).to eq('[0-9a-fA-F]') }
            it { expect(convert.call('[\R]')).to eq('[]') } # linebreak
            it { expect(convert.call('[\n]')).to eq('[]') }
            it { expect(convert.call('[\v]')).to eq('[]') }
            it { expect(convert.call('[\f]')).to eq('[]') }
            it { expect(convert.call('[\r]')).to eq('[]') }
          end

          describe 'POSIX char classes' do
            # https://www.regular-expressions.info/posixbrackets.html
            it { expect(convert.call('[[:alnum:]]')).to     eq('[[:alnum:]]') }
            it { expect(convert.call('[[:alpha:]]')).to     eq('[[:alpha:]]') }
            it { expect(convert.call('[[:blank:]]')).to     eq('[[:blank:]]') }
            it { expect(convert.call('[[:cntrl:]]')).to     eq('[[:cntrl:]]') }
            it { expect(convert.call('[[:digit:]]')).to     eq('[[:digit:]]') }
            it { expect(convert.call('[[:graph:]]')).to     eq('[[:graph:]]') }
            it { expect(convert.call('[[:lower:]]')).to     eq('[[:lower:]]') }
            it { expect(convert.call('[[:print:]]')).to     eq('[[:print:]]') }
            it { expect(convert.call('[[:punct:]]')).to     eq('[[:punct:]]') }
            it { expect(convert.call('[[:space:]]')).to     eq('[[:space:]]') }
            it { expect(convert.call('[[:upper:]]')).to     eq('[[:upper:]]') }
            it { expect(convert.call('[[:xdigit:]]')).to    eq('[[:xdigit:]]') }
            it { expect(convert.call('[[:return:]]')).to    eq('[[:return:]]') }
            it { expect(convert.call('[[:tab:]]')).to       eq('[[:tab:]]') }
            it { expect(convert.call('[[:escape:]]')).to    eq('[[:escape:]]') }
            it { expect(convert.call('[[:backspace:]]')).to eq('[[:backspace:]]') }

            it { expect(convert.call('[[:word:]]')).to      eq('[0-9a-zA-Z_]') }
            it { expect(convert.call('[[:ascii:]]')).to     eq('[\x00-\x7F]') }
          end
        end
      end

      describe 'Bracketed escapes' do
        it { expect(convert.call('[\x00]')).to eq('[\x00]') }
        it { expect(convert.call('[\xABCD]')).to eq('[\xABCD]') }
        it { expect(convert.call('[\x{00}]')).to eq('[\x00]') }
        it { expect(convert.call('[\x{ABCD}]')).to eq('[\xABCD]') }

        it { expect(convert.call('[\u00]')).to eq('[\u00]') }
        it { expect(convert.call('[\uABCD]')).to eq('[\uABCD]') }
        it { expect(convert.call('[\u{00}]')).to eq('[\u00]') }
        it { expect(convert.call('[\u{ABCD}]')).to eq('[\uABCD]') }

        it { expect(convert.call('[\o00]')).to eq('[\o00]') }
        it { expect(convert.call('[\o1234]')).to eq('[\o1234]') }
        it { expect(convert.call('[\o{00}]')).to eq('[\o00]') }
        it { expect(convert.call('[\o{1234}]')).to eq('[\o1234]') }

        # Note supported:
        # \N{U+hh..} character with Unicode code point hh.. (Unicode mode only)
      end

      describe 'groupping ()' do
        context 'when capturing' do
          it { expect(convert.call('(a)')).to     eq('\(a\)')    }
          it { expect(convert.call('(a)')).to     eq('\(a\)')    }
          it { expect(convert.call('(a|b)')).to   eq('\(a\|b\)') }
          it { expect(convert.call('(a|b)')).to   eq('\(a\|b\)') }
          it { expect(convert.call('((a))')).to   eq('\(\(a\)\)')    }
          it { expect(convert.call('((a))')).to   eq('\(\(a\)\)')    }
          it { expect(convert.call('((a|b))')).to eq('\(\(a\|b\)\)') }
          it { expect(convert.call('((a|b))')).to eq('\(\(a\|b\)\)') }

          it { expect(convert.call('(a)\(')).to eq('\(a\)(') }
          it { expect(convert.call('(a)\)')).to eq('\(a\))') }
          it { expect(convert.call('\((a)')).to eq('(\(a\)') }
          it { expect(convert.call('\)(a)')).to eq(')\(a\)') }
        end

        context 'when non-capturing' do
          # :h perl patterns
          # Capability                   in Vimspeak in Perlspeak
          # backref-less grouping        \%(atom\)   (?:atom)
          it { expect(convert.call('(?:a)')).to eq('\%(a\)') }
          it { expect(convert.call('(?:a)')).to eq('\%(a\)') }
          it { expect(convert.call('(?:a|b)')).to eq('\%(a\|b\)') }
          it { expect(convert.call('(?:a|b)')).to eq('\%(a\|b\)') }
        end

        context 'when named' do
          # https://www.pcre.org/original/doc/html/pcrepattern.html#SEC16
          it { expect(convert.call('(?<name>a)')).to eq('\(a\)') }  # pcre
          it { expect(convert.call("(?'name'a)")).to eq('\(a\)') }  # perl
          it { expect(convert.call('(?P<name>a)')).to eq('\(a\)') } # python
        end

        context 'when branch reset' do
          # https://www.rexegg.com/regex-disambiguation.html#branchreset
          it { expect(convert.call('(?|a)')).to eq('\(a\)') }
          it { expect(convert.call('(?|a)')).to eq('\(a\)') }
        end

        context 'when lookaround' do
          # :h perl patterns
          # Capability                   in Vimspeak in Perlspeak
          # ----------------------------------------------------------------
          # 0-width match                atom\@=     (?=atom)
          # 0-width non-match            atom\@!     (?!atom)
          # 0-width preceding match      atom\@<=    (?<=atom)
          # 0-width preceding non-match  atom\@<!    (?<!atom)
          # match without retry          atom\@>     (?>atom)

          context 'when lookahead' do
            context 'when positive' do
              it { expect(convert.call('1 (?=cat)')).to eq('1 \%(cat\)\@=') } # matches 1 in "1 cat"
            end

            context 'when negative' do
              it { expect(convert.call('1 (?!cat)')).to eq('1 \%(cat\)\@!') } # matches 1 in "1 dog"
            end
          end

          context 'when lookbehind' do
            context 'when positive' do
              it { expect(convert.call('(?<=\d) \w')).to eq('\%(\d\)\@<= \w') } # matches "b" in "a 2 b"
            end

            context 'when negative' do
              it { expect(convert.call('(?<!\d) \w')).to eq('\%(\d\)\@<! \w') } # matches "a" in "a 2 b"
            end
          end
          #  call assert_equal('\%(the\)\@>cat',    Parse('(?>the)cat')) " atomic
          #  call assert_equal((Parse('(?<=ab(?<!cd))')), '\%(ab\%(cd\)\@<!\)\@<=')
        end
      end

      describe 'modifiers' do
        # https://www.regular-expressions.info/tcl.html
        describe 'case' do
          # NOTE: that case spans are not supported as \c is global
          it { expect(convert.call('(?i)')).to eq('\c') }
          it { expect(convert.call('(?-i)')).to eq('') }
          it { expect(convert.call('(?i:abc)')).to eq('\cabc') }
          it { expect(convert.call('(?-i:abc)')).to eq('abc') }
        end

        describe 'newline-sensitivity' do
          it { expect(convert.call('(?m)')).to             eq('')      }
          it { expect(convert.call('(?m).')).to            eq('.')     }
          it { expect(convert.call('a(?m).c(?-m).')).to    eq('a.c.')  }
          it { expect(convert.call('a(?m:.c).')).to        eq('a.c.')  }
          it { expect(convert.call('a(?m:(?-m:.c).).')).to eq('a.c..') }
        end
      end

      describe 'special chars' do
        it { expect(convert.call('|')).to eq('\|') }
        it { expect(convert.call('\|')).to eq('|') }

        it { expect(convert.call('~')).to   eq('\~') }
        it { expect(convert.call('\~')).to  eq('\~') }

        it { expect(convert.call('\\\\')).to  eq('\\\\') }
        it { expect(convert.call('\\')).to    eq('\\') }

        it { expect(convert.call('\\%')).to eq('%') }
        it { expect(convert.call('%')).to eq('%') }

        it { expect(convert.call('\<')).to eq('<') }
        it { expect(convert.call('<')).to eq('<') }

        it { expect(convert.call('\>')).to eq('>') }
        it { expect(convert.call('>')).to eq('>') }

        it { expect(convert.call('\(')).to  eq('(') }
        it { expect(convert.call('\)')).to  eq(')') }
        it { expect(convert.call('()')).to  eq('\(\)') }

        it { expect(convert.call('\[')).to  eq('\[') }
        it { expect(convert.call('\]')).to  eq('\]') }
        it { expect(convert.call('[]')).to  eq('[]') }

        it { expect(convert.call('\=')).to  eq('=') }
        it { expect(convert.call('=')).to eq('=') }

        it { expect(convert.call('\@')).to eq('@') }
        it { expect(convert.call('@')).to eq('@') }

        it { expect(convert.call('\_.')).to eq('_.') }
        it { expect(convert.call('_.')).to eq('_.') }

        it { expect(convert.call('\&')).to   eq('&') }
        it { expect(convert.call('&')).to    eq('&') }
      end

      # https://www.rexegg.com/regex-anchors.html
      # https://www.pcre.org/current/doc/html/pcre2syntax.html#SEC10
      describe 'anchors' do
        describe 'word boundaries' do
          it { expect(convert.call('a\b')).to   eq('a\%(\<\|\>\)')            }
          it { expect(convert.call('\ba')).to   eq('\%(\<\|\>\)a')            }
          it { expect(convert.call('\ba\b')).to eq('\%(\<\|\>\)a\%(\<\|\>\)') }
        end

        describe 'subject boundaries' do
          it { expect(convert.call('^')).to  eq('^') }
          it { expect(convert.call('\A')).to eq('^') }
          it { expect(convert.call('$')).to  eq('$') }
          it { expect(convert.call('\z')).to eq('$') }
          it { expect(convert.call('\Z')).to eq('$') }
          it { expect(convert.call('\zs')).to eq('$s') }
          it { expect(convert.call('\ze')).to eq('$e') }
        end

        # TODO
        # \B     matches when not at a word boundary
        # \G     matches at the first matching position in the subject
      end

      describe 'quantifiers' do
        # https://www.rexegg.com/regex-quantifiers.html#cheat_sheet
        # :h perl patterns
        # Capability                   in Vimspeak in Perlspeak
        # ----------------------------------------------------------------
        # conservative quantifiers     \{-n,m}     *?, +?, ??, {}?
        context 'when zero or more *' do
          context 'when greedy' do
            it { expect(convert.call('a*')).to eq('a*') }
            it { expect(convert.call('(a)*')).to eq('\(a\)*') }
          end

          context 'when lazy' do
            it { expect(convert.call('a*?')).to eq('a\{-}') }
            it { expect(convert.call('(a)*?')).to eq('\(a\)\{-}') }
          end

          context 'when possessive' do
            it { expect(convert.call('a*+')).to eq('a*') }
            it { expect(convert.call('(a)*+')).to eq('\(a\)*') }
          end

          context 'when converted to literal' do
            it { expect(convert.call('a\*')).to eq('a\*') }
            it { expect(convert.call('a*\?')).to eq('a*?') }
            it { expect(convert.call('a\*?')).to eq('a\*\=') }
          end
        end

        context 'when once or more +' do
          context 'when greedy' do
            it { expect(convert.call('a+')).to eq('a\+') }
            it { expect(convert.call('(a)+')).to eq('\(a\)\+') }
          end

          context 'when lazy' do
            it { expect(convert.call('a+?')).to eq('a\{-1,}') }
            it { expect(convert.call('(a)+?')).to eq('\(a\)\{-1,}') }
          end

          context 'when possessive' do
            # Converted to greedy
            it { expect(convert.call('a++')).to eq('a\+') }
            it { expect(convert.call('(a)++')).to eq('\(a\)\+') }
          end

          context 'when converted to literal' do
            it { expect(convert.call('a\+')).to  eq('a+')   }
            it { expect(convert.call('a\+?')).to eq('a+\=') }
            it { expect(convert.call('a+\?')).to eq('a\+?') }
            it { expect(convert.call('a\++')).to eq('a+\+') }
            it { expect(convert.call('a+\+')).to eq('a\++') }
          end
        end

        context 'when zero or once ?' do
          context 'when greedy' do
            it { expect(convert.call('a?')).to   eq('a\=') }
            it { expect(convert.call('(a)?')).to eq('\(a\)\=') }
          end

          context 'when lazy' do
            it { expect(convert.call('a??')).to eq('a\{-,1}') }
            it { expect(convert.call('(a)??')).to eq('\(a\)\{-,1}') }
          end

          context 'when possessive' do
            it { expect(convert.call('a?+')).to eq('a\=') }
            it { expect(convert.call('(a)?+')).to eq('\(a\)\=') }
          end

          context 'when converted to literal' do
            it { expect(convert.call('a\?')).to  eq('a?')   }
            it { expect(convert.call('a\??')).to eq('a?\=') }
            it { expect(convert.call('a?\?')).to eq('a\=?') }
            it { expect(convert.call('a\??')).to eq('a?\=') }
            it { expect(convert.call('a\?\?')).to eq('a??') }
          end
        end

        context 'when zero or once {n,m}' do
          # From :h /multi
          # \{n,m}    n to m as many as possible
          # \{n}      n exactly
          # \{n,}     at least n  as many as possible
          # \{,m}     0 to m as many as possible
          # \{}       0 or more as many as possible (same as *)
          # \{-n,m}   n to m as few as possible
          # \{-n}     n exactly
          # \{-n,}    at least n  as few as possible
          # \{-,m}    0 to m    as few as possible
          # \{-}      0 or more as few as possible

          # https://docs.microsoft.com/en-us/dotnet/standard/base-types/quantifiers-in-regular-expressions
          # https://www.regular-expressions.info/refrepeat.html
          context 'when greedy' do
            it { expect(convert.call('a{1,2}')).to eq('a\{1,2}') }
            it { expect(convert.call('a{1,}')).to  eq('a\{1,}')  }
            it { expect(convert.call('a{3}')).to   eq('a\{3}')   }

            it { expect(convert.call('(a){1,2}')).to eq('\(a\)\{1,2}') }
            it { expect(convert.call('(a){1,}')).to  eq('\(a\)\{1,}')  }
            it { expect(convert.call('(a){3}')).to   eq('\(a\)\{3}')   }
          end

          context 'when lazy' do
            it { expect(convert.call('(a){1,2}?')).to eq('\(a\)\{-1,2}') }
            it { expect(convert.call('(a){1,}?')).to  eq('\(a\)\{-1,}')  }
            it { expect(convert.call('(a){3}?')).to   eq('\(a\)\{-3}')   }
          end

          context 'when possessive' do
            # Converted to greedy
            it { expect(convert.call('(a){1,2}+')).to eq('\(a\)\{1,2}') }
            it { expect(convert.call('(a){1,}+')).to  eq('\(a\)\{1,}')  }
            it { expect(convert.call('(a){3}+')).to   eq('\(a\)\{3}')   }
          end

          context 'when converted to literal' do
            it { expect(convert.call('a{,2}')).to  eq('a{,2}')   }
            it { expect(convert.call('a{,2}+')).to eq('a{,2}\+') }
            it { expect(convert.call('a{,2}?')).to eq('a{,2}\=') }
            it { expect(convert.call('a{,}?')).to  eq('a{,}\=')  }
            it { expect(convert.call('\{}')).to    eq('{}')      }
            it { expect(convert.call('\{')).to     eq('{')       }
            it { expect(convert.call('\{\}')).to   eq('{\}')     }
            it { expect(convert.call('a{}')).to    eq('a{}')     }
            it { expect(convert.call('a{,}')).to   eq('a{,}')    }
            it { expect(convert.call('a{-}')).to   eq('a{-}')    }
            it { expect(convert.call('a{')).to     eq('a{')      }
            it { expect(convert.call('a}')).to     eq('a}')      }
          end
        end
      end
    end
  end
end
