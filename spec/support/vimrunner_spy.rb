class VimrunnerSpy < BaseDecorator
  include TaggedLogging

  def self.echo_call_history
    @@echo_call_history ||= []
  end

  def self.reset!
    @@echo_call_history = []
  end

  def echo(arg)
    @@echo_call_history ||= []
    @@echo_call_history << [arg, clean_caller]
    super(arg)
  end
end

