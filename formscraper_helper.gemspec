Gem::Specification.new do |s|
  s.name = 'formscraper_helper'
  s.version = '0.3.0'
  s.summary = 'Attempts to scrape the inputs required to complete a 1 page online form.'
  s.authors = ['James Robertson']
  s.files = Dir["lib/formscraper_helper.rb"]
  s.add_runtime_dependency('ferrumwizard', '~> 0.3', '>=0.3.2')
  s.add_runtime_dependency('nokorexi', '~> 0.7', '>=0.7.0')
  s.signing_key = '../privatekeys/formscraper_helper.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'digital.robertson@gmail.com'
  s.homepage = 'https://github.com/jrobertson/formscraper_helper'
end
