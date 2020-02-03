# frozen_string_literal: true

class Client < DecoratorBase
  def echo(*expressions)
    arg = expressions.join(' ').gsub("'", "''")
    server.remote_expr("VimrunnerEvaluate('#{arg}')")
  end

  def feedkeys(string)
    string = string.gsub('"', '\"')
    command(%{call feedkeys("#{string}", "i")})
  end
end
