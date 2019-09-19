# frozen_string_literal: true

module AdGear
  module Infrastructure
    module JfrogCli
      module Out
        require('fileutils')
        require('json')
        require('mixlib/shellout')
        require('mixlib/versioning')
        require('pathname')

        require_relative('./logging')
        require_relative('./util')
        include AdGear::Infrastructure::JfrogCli::Logging
        include AdGear::Infrastructure::JfrogCli::Util

        class OutAction
          def initialize(data)
            stdin = JSON.parse(data, symbolize_names: false)
            ret = {
              version: { version: stdin['version']['version'] },
              metadata: [
                { name: 'version', value: stdin['version']['version'] }
              ]
            }

            resource_folder = ARGV[1] || Dir.pwd
            Log.debug(resource_folder)

            unless ENV.key?('source_folder')
              Log.fatal('The `source_folder` parameter must be specified') 
            end

            source_file = File.join(
              resource_folder,
              ENV['source_folder'],
              stdin['source']['artifact_name'] + '-' +
              stdin['source']['qualifier'] + '-' +
              stdin['version']['version'] +
              stdin['source']['extension']
            )

            ret[:metadata] << { name: 'file', value: File.basename(source_file) }

            Log.debug(source_file)
            Log.debug(JSON.pretty_generate(stdin.to_h))

            workdir = Dir.mktmpdir(nil, '/tmp')
            Log.debug("Created #{workdir}")

            env = {
              'JFROG_CLI_REPORT_USAGE': 'false',
              'JFROG_CLI_HOME_DIR': workdir,
              'JFROG_CLI_LOG_LEVEL': ENV['LOG_LEVEL'] || 'INFO',
              'CI': 'true'
            }

            begin
              Log.info('Priming configuration...')
              configure_command = [
                'jfrog', 'rt', 'config',
                '--url', stdin['source']['url'],
                '--user', stdin['source']['username'],
                '--password', stdin['source']['password']
              ].join(' ')

              configure = Mixlib::ShellOut.new(configure_command, environment: env)
              configure.run_command
              configure.error!

              Log.debug(configure.stderr)
              Log.debug(configure.stdout)

              push_destination = File.join(
                stdin['source']['repository'],
                stdin['source']['path'],
                stdin['source']['artifact_name'],
                stdin['version']['version'],
                '/'
              )
              Log.debug(push_destination)

              push_command = [
                'jfrog', 'rt', 'upload',
                '--fail-no-op',
                source_file,
                push_destination
              ].join(' ')

              Log.info("Pushing #{File.basename(source_file)} to Artifactory...")
              pull = Mixlib::ShellOut.new(push_command, environment: env)
              pull.run_command
              pull.error!

              Log.debug(pull.stderr)
              Log.debug(pull.stdout)

              if JSON.parse(pull.stdout)['status'] != 'success'
                Log.fatal(pull.stderr)
              end
            ensure
              Log.debug(Dir.glob(File.join(workdir, '*')))
              FileUtils.rm_rf(workdir)
              Log.debug("Deleted #{workdir}")
            end

            puts(JSON.pretty_generate(ret))
          end
        end
      end
    end
  end
end
