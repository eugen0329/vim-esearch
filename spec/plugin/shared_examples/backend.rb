RSpec.shared_examples 'a backend' do |backend, adapter, test_queries|
  before :each do
    press ':cd $PWD<Enter>'
    press ':cd spec/fixtures/backend/<Enter>'
    esearch_settings(backend: backend, adapter: adapter)
  end

  test_queries.each do |test_query|
    it "properly escapes `#{test_query}`" do
      press ":call esearch#init()<Enter>#{test_query}<Enter>"

      expected = expect {
        press("<Nop>") # preto skip "Press ENTER or type command to continue" prompt
        bufname("%") =~ /Search/
      }.to become_true_within(3.second)

      expect { line(1) =~ /Finish/i }.to become_true_within(5.second),
        -> { "Expected first line to match /Finish/, got `#{line(1)}`" }
    end
  end
end
