# frozen_string_literal: true

require 'spec_helper'

describe 'esearch#ftdetect' do
  include VimlValue::SerializationHelpers

  shared_examples 'detects ft with fast strategy' do
    it { expect(ftdetect.call('main.go')).to        eq('go')              }
    it { expect(ftdetect.call('main.r')).to         eq('r')               }
    it { expect(ftdetect.call('main.sql')).to       eq('sql')             }
    it { expect(ftdetect.call('main.tex')).to       eq('tex')             }
    it { expect(ftdetect.call('main.asm')).to       eq('asm')             }
    it { expect(ftdetect.call('main.pl')).to        eq('perl')            }
    it { expect(ftdetect.call('main.java')).to      eq('java')            }
    it { expect(ftdetect.call('main.mof')).to       eq('msidl')           }
    it { expect(ftdetect.call('file.toml')).to      eq('toml')            }
    it { expect(ftdetect.call('package.json')).to   eq('json')            }

    # js and dialects
    it { expect(ftdetect.call('main.js')).to        eq('javascript')      }
    it { expect(ftdetect.call('main.ts')).to        eq('typescript')      }
    it { expect(ftdetect.call('main.coffee')).to    eq('coffee')          }

    # react
    it { expect(ftdetect.call('main.jsx')).to       eq('javascriptreact') }
    it { expect(ftdetect.call('main.tsx')).to       eq('typescriptreact') }

    # swift
    xit { expect(ftdetect.call('main.swift')).to eq('swift') }

    # haskell
    it { expect(ftdetect.call('main.hs')).to        eq('haskell')         }
    it { expect(ftdetect.call('main.lhs')).to       eq('lhaskell')        }

    # hcl
    it { expect(ftdetect.call('main.tf')).to        eq('hcl')             }
    it { expect(ftdetect.call('main.tfvars')).to    eq('hcl')             }
    it { expect(ftdetect.call('main.hcl')).to       eq('hcl')             }

    # groovy
    it { expect(ftdetect.call('main.gradle')).to    eq('groovy')          }
    it { expect(ftdetect.call('main.groovy')).to    eq('groovy')          }

    # css
    it { expect(ftdetect.call('main.css')).to       eq('css')             }
    it { expect(ftdetect.call('main.sass')).to      eq('sass')            }
    it { expect(ftdetect.call('main.scss')).to      eq('scss')            }
    it { expect(ftdetect.call('main.less')).to      eq('less')            }

    # php
    it { expect(ftdetect.call('main.php')).to       eq('php')             }
    it { expect(ftdetect.call('main.phtml')).to     eq('php')             }

    # c
    it { expect(ftdetect.call('main.xs')).to        eq('xs')              }
    it { expect(ftdetect.call('main.x')).to         eq('rpcgen')          }
    it { expect(ftdetect.call('main.h')).to         eq('c')               }
    it { expect(ftdetect.call('main.c')).to         eq('c')               }
    it { expect(ftdetect.call('main.cmod')).to      eq('cmod')            }
    it { expect(ftdetect.call('main.cpp')).to       eq('cpp')             }
    it { expect(ftdetect.call('main.cc')).to        eq('cpp')             }
    it { expect(ftdetect.call('main.hpp')).to       eq('cpp')             }

    it { expect(ftdetect.call('main.m')).to         eq('objc')            }

    # xml
    it { expect(ftdetect.call('file.svg')).to       eq('svg')             }
    it { expect(ftdetect.call('pom.xml')).to        eq('xml')             }
    it { expect(ftdetect.call('index.papp')).to     eq('papp')            }

    # yaml
    it { expect(ftdetect.call('locales.liquid')).to eq('liquid')          }
    it { expect(ftdetect.call('locales.yaml')).to   eq('yaml')            }
    it { expect(ftdetect.call('locales.yml')).to    eq('yaml')            }

    # ruby
    it { expect(ftdetect.call('main.rb')).to        eq('ruby')            }
    it { expect(ftdetect.call('Gemfile')).to        eq('ruby')            }

    # python
    it { expect(ftdetect.call('main.py')).to        eq('python')          }
    it { expect(ftdetect.call('main.kv')).to        eq('kivy')            }
    it { expect(ftdetect.call('main.pyx')).to       eq('pyrex')           }
    it { expect(ftdetect.call('main.pxd')).to       eq('pyrex')           }

    # html
    it { expect(ftdetect.call('index.html')).to     eq('html')            }
    it { expect(ftdetect.call('index.xhtml')).to    eq('xhtml')           }
    it { expect(ftdetect.call('index.haml')).to     eq('haml')            }
    it { expect(ftdetect.call('index.md')).to       eq('markdown')        }
    it { expect(ftdetect.call('index.tmpl')).to     eq('template')        }
    it { expect(ftdetect.call('index.wml')).to      eq('wml')             }
    it { expect(ftdetect.call('index.jsp')).to      eq('jsp')             }
    it { expect(ftdetect.call('index.vue')).to      eq('vue')             }

    # sh
    it { expect(ftdetect.call('script.bash')).to    eq('sh')              }
    it { expect(ftdetect.call('script.sh')).to      eq('sh')              }
    it { expect(ftdetect.call('script.bats')).to    eq('sh')              }
    it { expect(ftdetect.call('script.zsh')).to     eq('zsh')             }

    it { expect(ftdetect.call('Dockerfile')).to     eq('dockerfile')      }
  end

  describe '#slow' do
    subject(:ftdetect) do
      ->(filename) { editor.echo func('esearch#ftdetect#slow', filename) }
    end

    include_examples 'detects ft with fast strategy'

    it { expect(ftdetect.call('main.vhdl')).to   eq('vhdl')    }
    it { expect(ftdetect.call('main.v')).to      eq('verilog') }
    it { expect(ftdetect.call('main.vhdl_1')).to eq('vhdl')    }
    it { expect(ftdetect.call('Makefile')).to    eq('make')    }

    context 'opened buffers' do
      context 'when exists' do
        before do
          editor.edit! 'Testfile'
          editor.command! 'set ft=test_filetype'
        end
        after { editor.cleanup! }

        it 'grabs filetype from them' do
          expect(ftdetect.call('Testfile')).to eq('test_filetype')
        end
      end

      context "when doesn't exist" do
        after { editor.cleanup! }

        it { expect(ftdetect.call('Testfile')).to be_blank | eq(0) }
      end
    end
  end

  describe '#fast' do
    subject(:ftdetect) do
      ->(filename) { editor.echo func('esearch#ftdetect#fast', filename) }
    end

    include_examples 'detects ft with fast strategy'
  end
end
