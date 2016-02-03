require File.expand_path('../lib/mongoid_session_store/version', __FILE__)

Gem::Specification.new do |s|
  s.name = File.basename(__FILE__).gsub('.gemspec', '')
  s.version = MongoidSessionStore::VERSION

  s.authors          = ['Máximo Mussini']
  s.email            = ['maximomussini@gmail.com']
  s.files            = `git ls-files`.split("\n")
  s.test_files       = `git ls-files -- {test,spec,features,perf}/*`.split("\n")
  s.homepage         = 'http://github.com/SolarCS/mongoid_session_store'
  s.license          = 'MIT'
  s.require_paths    = ['lib']
  s.rubygems_version = '1.3.7'
  s.summary          = 'Mongoid session store for Rails'
  s.add_dependency 'actionpack', '>= 3.1'
end
