# frozen_string_literal: true

require 'rbconfig'

module PlatformCheck
  def platform_name
    @platform_name ||=
      if linux?
        :linux
      elsif osx?
        :osx
      else
        raise 'Unknown platform'
      end
  end

  def osx?
    @osx = RbConfig::CONFIG['host_os'].match?(/darwin/) if @osx.nil?
    @osx
  end

  def linux?
    @linux = RbConfig::CONFIG['host_os'].match?(/linux/) if @linux.nil?
    @linux
  end
end
