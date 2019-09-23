# frozen_string_literal: true

module AdGear
  module Infrastructure
    module JfrogCli
      module Check
        require('fileutils')
        require('json')
        require('mixlib/shellout')
        require('mixlib/versioning')

        require_relative('./logging')
        require_relative('./util')
        include AdGear::Infrastructure::JfrogCli::Logging
        include AdGear::Infrastructure::JfrogCli::Util

        class CheckAction
          def initialize(data)
            stdin = JSON.parse(data, symbolize_names: false)
            ret = []

            validate_stdin(stdin)

            unless stdin.dig('version', 'version')
              stdin['version'] = { 'version': '0.0.0' }
            end

            Log.debug(JSON.pretty_generate(stdin.to_h))

            workdir = Dir.mktmpdir(nil, '/tmp')
            Log.debug("Created #{workdir}")

            env = {
              'JFROG_CLI_REPORT_USAGE': 'false',
              'JFROG_CLI_HOME_DIR': workdir,
              'JFROG_CLI_LOG_LEVEL': ENV['LOG_LEVEL'] || 'INFO',
              'CI': 'true'
            }

            oldest_version = Mixlib::Versioning.parse(stdin['version']['version'])

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

              search_path = File.join(
                stdin['source']['repository'],
                stdin['source']['path'],
                stdin['source']['artifact_name'],
                '**',
                stdin['source']['artifact_name'] + '-' +
                stdin['source']['qualifier'] + '-' \
                '*' +
                stdin['source']['extension']
              )

              search_command = [
                'jfrog', 'rt', 'search',
                '--limit', '100',
                '--sort-by', 'path',
                '--sort-order', 'desc',
                '--fail-no-op',
                search_path
              ].join(' ')

              Log.info('Performing query...')
              search = Mixlib::ShellOut.new(search_command, environment: env)
              search.run_command
              search.error!

              Log.debug(search.stderr)
              Log.debug(search.stdout)

              found_files = JSON.parse(search.stdout).map { |i| i['path'] }

              versions = found_files.map do |i|
                File.basename(i, stdin['source']['extension'])
                    .gsub(stdin['source']['artifact_name'] + '-' + stdin['source']['qualifier'] + '-', '')
              end

              versions.uniq!
              versions.map! { |i| Mixlib::Versioning.parse(i) }
              Log.info("Artifactory reports #{versions.length} versions")

              Log.debug(versions.map(&:to_s))

              new_versions = versions.select { |i| i > oldest_version }
              Log.info("Found #{new_versions.length} newer versions")

              Log.debug(new_versions.map(&:to_s))

              ret = new_versions.map { |v| { version: v.to_s } }
            ensure
              Log.debug(Dir.glob(File.join(workdir, '*')))
              FileUtils.rm_rf(workdir)
              Log.debug("Deleted #{workdir}")
            end

            puts(ret.to_json)
          end
        end
      end
    end
  end
end
