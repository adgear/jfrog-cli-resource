# frozen_string_literal: true

# The global logging instance. Sends stuff to STDERR.
# @since 0.1.0
module AdGear
  module Infrastructure
    module JfrogCli
      module Logging
        require('logger')

        Log = Logger.new(STDERR)
        Log.level = ENV['LOG_LEVEL'] || :info

        Log.formatter = proc do |_severity, _datetime, _progname, msg|
          "#{msg}\n"
        end

        def Log.fatal(*args)
          Log.error(*args)
          exit(1)
        end
      end
    end
  end
end
