RSpec.shared_examples 'a backend' do |backend, test_queries|
  before :each do
    press ':cd $PWD<ENTER>'
    press ':cd spec/fixtures/backend/<ENTER>'
    cmd "let g:esearch = { 'backend': '#{backend}' }"
  end

  test_queries.each do |test_query|
    it "properly escapes `#{test_query}`" do
      press ":call esearch#init()<Enter>#{test_query}<Enter>"

      expected = expect {
        # press("<Nop>") # preto skip "Press ENTER or type command to continue" prompt
        bufname("%") =~ /Search/
      }.to become_true_within(3.second)

      expect { line(1) =~ /Finish/i }.to become_true_within(5.second),
        -> { "Expected first line to match /Finish/, got `#{line(1)}`" }
    end
  end
end
