require File.dirname(__FILE__) + '/background_lite/background'
require File.dirname(__FILE__) + '/background_lite/core_ext/object'
require File.dirname(__FILE__) + '/background_lite/core_ext/class'
require File.dirname(__FILE__) + '/background_lite/core_ext/numeric'
require File.dirname(__FILE__) + '/background_lite/core_ext/symbol'
require File.dirname(__FILE__) + '/background_lite/core_ext/nil_class'
Dir.glob(File.dirname(__FILE__) + '/background_lite/core_ext/handlers/*.rb').each do |handler|
  require handler
end
Dir.glob(File.dirname(__FILE__) + '/background_lite/core_ext/error_reporters/*.rb').each do |reporter|
  require reporter
end
require File.dirname(__FILE__) + '/background_lite/rails_ext/activerecord/base'
