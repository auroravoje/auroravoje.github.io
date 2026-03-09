#!/usr/bin/env ruby

require 'openssl'
require 'net/http'

# Monkey-patch Net::HTTP to disable SSL verification
module Net
  class HTTP
    alias_method :original_use_ssl=, :use_ssl=
    
    def use_ssl=(flag)
      self.original_use_ssl = flag
      if flag
        self.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
    end
  end
end

# Now require Jekyll and run
require 'jekyll'
require 'jekyll/commands/serve'

Jekyll::Commands::Serve.process(ARGV)
