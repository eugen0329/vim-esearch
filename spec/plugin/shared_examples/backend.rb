RSpec.shared_examples 'a backend' do |backend, adapter|
  ADAPTERS = ['grep', 'ag', 'ack']

  ADAPTERS.each do |adapter|
    context "#{adapter} adapter" do
      before :each do
        press ':cd $PWD<Enter>'
        press ':cd spec/fixtures/backend/<Enter>'
        esearch_settings(backend: backend, adapter: adapter)
      end

      after :each do |example|
        cmd('close!') if bufname("%") =~ /Search/
      end


      ['<', '>', '"', "'", '(', ')', '(', '[', ']', "`", '$', '^', '++', '**', '==', '//', '\\\\', '\/']
        .each do |test_query|
        it "properly escapes `#{test_query}`" do
          press ":call esearch#init()<Enter>#{test_query}<Enter>"

          expected = expect {
            press("j") # preto skip "Press ENTER or type command to continue" prompt
            bufname("%") =~ /Search/
          }.to become_true_within(5.second)

          expect { line(1) =~ /Finish/i }.to become_true_within(10.seconds),
            -> { "Expected first line to match /Finish/, got `#{line(1)}`" }
        end
      end
    end
  end

  include_context 'dumpable'
end
