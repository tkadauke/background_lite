require File.dirname(__FILE__) + '/lib/background'
require File.dirname(__FILE__) + '/lib/core_ext/object'
require File.dirname(__FILE__) + '/lib/core_ext/class'
require File.dirname(__FILE__) + '/lib/core_ext/numeric'
require File.dirname(__FILE__) + '/lib/core_ext/symbol'
require File.dirname(__FILE__) + '/lib/core_ext/nil_class'
Dir.glob(File.dirname(__FILE__) + '/lib/core_ext/handlers/*.rb').each do |handler|
  require handler
end
Dir.glob(File.dirname(__FILE__) + '/lib/core_ext/error_reporters/*.rb').each do |reporter|
  require reporter
end
require File.dirname(__FILE__) + '/lib/rails_ext/activerecord/base'
