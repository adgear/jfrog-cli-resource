require_relative('lib/version')
include AdGear::Infrastructure::JfrogCli::Version

Gem::Specification.new do |s|
  s.name = 'jfrog-cli-resource'
  s.authors = [
    'Alexis Vanier'
  ]
  s.version = GEM_VERSION
  s.date = '2019-04-30'
  s.summary = 'Concourse resource using the JFrog CLI'
  s.files = Dir.glob('lib/**/*')
  s.files += %w[LICENSE README.md Gemfile]
  s.files += Dir.glob('assets/**/*')
  s.bindir = 'assets'
  s.executables = Dir.glob('assets/**/*').map { |f| File.basename(f) }
  s.require_paths = ['lib']
  s.licenses = ['MIT']
  s.homepage = 'https://www.github.com/adgear/jfrog-cli-resource'
  s.add_dependency('mixlib-shellout', '~> 3.0')
  s.add_dependency('mixlib-versioning', '~> 1.2')
end
