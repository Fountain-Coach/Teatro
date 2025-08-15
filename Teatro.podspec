Pod::Spec.new do |s|
  s.name         = 'Teatro'
  s.version      = '0.2.0'
  s.summary      = 'Declarative rendering framework.'
  s.homepage     = 'https://github.com/fountain-coach/teatro'
  s.license      = { :type => 'MIT' }
  s.author       = { 'FountainCoach' => 'support@fountain.coach' }
  s.source       = { :git => 'https://github.com/fountain-coach/teatro.git', :tag => s.version.to_s }
  s.swift_version = '6.1'
  s.source_files  = 'Sources/**/*.{swift}'
end
