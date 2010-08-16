Gem::Specification.new do |s| 
  s.platform  =   Gem::Platform::RUBY
  s.name      =   "background_lite"
  s.version   =   "0.2.2"
  s.date      =   Date.today.strftime('%Y-%m-%d')
  s.author    =   "Thomas Kadauke"
  s.email     =   "tkadauke@imedo.de"
  s.homepage  =   "http://www.imedo.de/"
  s.summary   =   "Run any method in the background"
  s.files     =   Dir.glob("{lib,rails}/**/*") + Dir.glob("*.rb")

  s.has_rdoc = true
  s.extra_rdoc_files = ["README.rdoc"]
  
  s.require_path = "lib"
end
