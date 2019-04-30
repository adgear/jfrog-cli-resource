require_relative('lib/version')
include AdGear::Infrastructure::ArtifactoryResource::Version

Gem::Specification.new do |s|
  s.name = 'artifactory-resource'
  s.authors = [
    'Alexis Vanier'
  ]
  s.version = GEM_VERSION
  s.date = '2019-04-30'
  s.summary = 'Concourse resource for Artifactory'
  s.files = Dir.glob('{bin,lib}/**/*') + %w[LICENSE README.md Gemfile]
  s.require_paths = ['lib']
  s.executables = ['ldap-group-manager']
  s.licenses = ['MIT']
  s.homepage = 'https://www.github.com/adgear/artifactory-resource'
end
