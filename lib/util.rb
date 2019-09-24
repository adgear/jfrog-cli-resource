module AdGear
  module Infrastructure
    module JfrogCli
      module Util
        require_relative('./logging')
        include AdGear::Infrastructure::JfrogCli::Logging

        module_function

        def validate_stdin(stdin)
          unless stdin.key?('source')
            Log.fatal("Missing key 'source' in stdin")
          end

          %W[
            url
            username
            password
            repository
            path
            artifact_name
            qualifier
            extension
          ].each do |k|
            Log.fatal("Missing key 'source.#{k}' in stdin") unless stdin['source'].key?(k)
          end
        end
      end
    end
  end
end
