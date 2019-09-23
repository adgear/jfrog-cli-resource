# frozen_string_literal: true

module AdGear
  module Infrastructure
    module JfrogCli
      module In
        require('fileutils')
        require('json')
        require('mixlib/shellout')
        require('mixlib/versioning')

        require_relative('./logging')
        require_relative('./util')
        include AdGear::Infrastructure::JfrogCli::Logging
        include AdGear::Infrastructure::JfrogCli::Util

        class InAction
          def initialize(data, argv = [])
            stdin = JSON.parse(data, symbolize_names: false)
            validate_stdin(stdin)

            ret = {
              version: { version: stdin['version']['version'] },
              metadata: [
                { name: 'version', value: stdin['version']['version'] }
              ]
            }

            download_location = argv[1] || Dir.pwd

            Log.debug(download_location)
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

              pull_path = File.join(
                stdin['source']['repository'],
                stdin['source']['path'],
                stdin['source']['artifact_name'],
                stdin['version']['version'],
                stdin['source']['artifact_name'] + '-' +
                stdin['source']['qualifier'] + '-' +
                stdin['version']['version'] +
                stdin['source']['extension']
              )

              ret[:metadata] << { name: 'file', value: pull_path }

              pull_command = [
                'jfrog', 'rt', 'download',
                pull_path,
                download_location + '/'
              ].join(' ')

              Log.info("Pulling version #{stdin['version']['version']} from Artifactory...")
              pull = Mixlib::ShellOut.new(pull_command, environment: env)
              pull.run_command
              pull.error!

              Log.debug(pull.stderr)
              Log.debug(pull.stdout)

              parsed_stdout = JSON.parse(pull.stdout)

              if parsed_stdout['status'] != 'success' || parsed_stdout['totals']['success'] <= 0
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
