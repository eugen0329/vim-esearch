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

      describe 'groupping ()' do
        context 'when capturing' do
          it { expect(convert.call('(a)')).to eq('\(a\)') }
          it { expect(convert.call('(a)')).to eq('\(a\)') }
          it { expect(convert.call('(a|b)')).to eq('\(a\|b\)') }
          it { expect(convert.call('(a|b)')).to eq('\(a\|b\)') }

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
          # force case insensitivity     \c          (?i)
          # force case sensitivity       \C          (?-i)
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
          # :h perl patterns
          # Capability                   in Vimspeak in Perlspeak
          # ----------------------------------------------------------------
          # force case insensitivity     \c          (?i)
          # force case sensitivity       \C          (?-i)

          # When "\c" appears anywhere in the pattern, the whole pattern is handled like
          # 'ignorecase' is on.  The actual value of 'ignorecase' and 'smartcase' is
          # ignored.
          # Thus, case spans aren't supported.
          it { expect(convert.call('(?i)')).to eq('\c') }
          it { expect(convert.call('(?-i)')).to eq('\C') }
          it { expect(convert.call('(?i:abc)')).to eq('\cabc') }
          it { expect(convert.call('(?-i:abc)')).to eq('\Cabc') }
        end

        describe 'newline-sensitivity' do
          it { expect(convert.call('(?m)')).to             eq('')      }
          it { expect(convert.call('(?m).')).to            eq('.')     }
          it { expect(convert.call('a(?m).c(?-m).')).to    eq('a.c.')  }
          it { expect(convert.call('a(?m:.c).')).to        eq('a.c.')  }
          it { expect(convert.call('a(?m:(?-m:.c).).')).to eq('a.c..') }
          #  \_. Matches any single character or end-of-line.
          #  " Careful: "\_.*" matches all text to the end of the buffer!
          # it { expect(convert.call('(?m)')).to             eq('')        }
          # it { expect(convert.call('(?m).')).to            eq('\_.')     }
          # it { expect(convert.call('a(?m).c(?-m).')).to    eq('a\_.c.')  }
          # it { expect(convert.call('a(?m:.c).')).to        eq('a\_.c.')  }
          # it { expect(convert.call('a(?m:(?-m:.c).).')).to eq('a.c\_..') }
        end
      end

      describe 'other special chars' do
        # Examples:
        # after:    \v      \m      \M      \V              matches    ~
        #                 'magic' 'nomagic'
        #           $       $        $      \$   matches    end-of-line
        #           .       .        \.     \.   matches    any        character
        #           *       *        \*     \*   any        number     of the previous atom
        #           ~       ~        \~     \~   latest     substitute string
        #           ()      \(\)     \(\)   \(\) grouping   into       an atom
        #           |       \|       \|     \|   separating alternatives
        #           \a      \a       \a     \a   alphabetic character
        #           \\      \\       \\     \\   literal    backslash
        #           \.      \.       .      .    literal    dot
        #           \{      {        {      {    literal    '{'
        #           a       a        a      a    literal    'a'

        # "" \& - branching (same as \|)
        #   " Note that using "\&" works the same as using "\@=": "foo\&.." is the
        #   " same as "\(foo\)\@=..".  But using "\&" is easier, you don't need the
        #   " braces.
        it { expect(convert.call('|')).to  eq('\|') }
        it { expect(convert.call('~')).to  eq('\~') }
        it { expect(convert.call('\\')).to eq('\\') }
        it { expect(convert.call('|')).to  eq('\|') }
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
          it { expect(convert.call('\A')).to eq('\%^') } # TODO
          it { expect(convert.call('$')).to  eq('$') }
          it { expect(convert.call('\z')).to eq('\%$') } # TODO
        end

        # TODO
        # \B     matches when not at a word boundary
        # \z     matches only at the end of the subject
        # \G     matches at the first matching position in the subject
      end

      describe 'quantifiers' do
        # https://www.rexegg.com/regex-quantifiers.html#cheat_sheet
        context 'when zero or more *' do
          it { expect(convert.call('a*')).to eq('a*') }
          it { expect(convert.call('a\*')).to eq('a\*') }

          # TODO: a*?
          # TODO: a*+
        end

        context 'when once or more +' do
          it { expect(convert.call('a+')).to eq('a\+') }
          it { expect(convert.call('a\+')).to eq('a+') }
          # TODO: a+?
          # TODO: a++
        end

        context 'when zero or once ?' do
          # cats?1  searches cats1, then cat1
          # cats??1 searches cat1, then cats1
          it { expect(convert.call('a?')).to   eq('a\=')     } # greedy
          it { expect(convert.call('a??')).to  eq('a\{-,1}') } # lazy

          it { expect(convert.call('(a)?')).to   eq('\(a\)\=')     }
          it { expect(convert.call('(a)??')).to  eq('\(a\)\{-,1}') }

          it { expect(convert.call('a?\?')).to   eq('a\=?')     }
          it { expect(convert.call('a\??')).to   eq('a?\=')     }
        end

        context 'when zero or once {n,m}' do
          # :h perl patterns
          # Capability                   in Vimspeak in Perlspeak
          # ----------------------------------------------------------------
          # conservative quantifiers     \{-n,m}     *?, +?, ??, {}?

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
          context 'when fixed' do
            it { expect(convert.call('a{}')).to eq('a\{}') }
            it { expect(convert.call('a{3}')).to eq('a\{3}') }
            it { expect(convert.call('a{3}?')).to eq('a\{-3}') }
          end

          context 'when greedy' do
            it { expect(convert.call('a{1,2}')).to  eq('a\{1,2}')  }
            it { expect(convert.call('a{1,}')).to   eq('a\{1,}')   }
            it { expect(convert.call('a{,2}')).to   eq('a\{,2}')   }
          end

          context 'when lazy' do
            it { expect(convert.call('a{1,2}?')).to eq('a\{-1,2}') }
            it { expect(convert.call('a{1,}?')).to  eq('a\{-1,}') }
            it { expect(convert.call('a{,2}?')).to  eq('a\{-,2}') }
          end

          context 'when possessive' do
            # TODO: a{1,2}+
          end
        end
      end
    end
  end
end
