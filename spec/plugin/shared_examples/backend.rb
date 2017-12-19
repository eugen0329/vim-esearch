RSpec.shared_examples 'a backend' do |backend, adapter|
  adapters = ['ack', 'ag', 'git', 'grep', 'pt', 'rg']
  adapters -= ['rg', 'pt'] if ENV['TRAVIS_OS_NAME'] == 'linux'

  adapters.each do |adapter|
    context "with #{adapter} adapter" do
      around do |example|
        working_directory = ENV.fetch('TRAVIS_BUILD_DIR', '$PWD')
        press ":cd #{working_directory}<Enter>"
        press ':cd spec/fixtures/backend/<Enter>'
        esearch_settings(backend: backend, adapter: adapter)

        example.run

        cmd('close!') if bufname("%") =~ /Search/
      end

      context 'literal' do
        settings_dependent_context('literal', regex: 0)
      end

      context 'regex' do
        settings_dependent_context('regex', regex: 1)
      end
    end
  end

  include_context 'dumpable'
end

# TODO
def settings_dependent_context(type, settings)
  before { esearch_settings(settings) }

  File.readlines("spec/fixtures/backend/#{type}.txt").map(&:chomp).each do |test_query|
    it "finds `#{test_query}`" do
      press ":call esearch#init()<Enter>#{test_query}<Enter>"
      # require 'pry'; binding.pry

      expect {
        press("j") # press j to close "Press ENTER or type command to continue" prompt
        bufname("%") =~ /Search/
      }.to become_true_within(5.second)

      expect { line(1) =~ /Finish/i }.to become_true_within(10.seconds),
        -> { "Expected first line to match /Finish/, got `#{line(1)}`" }
    end
  end
end
