if defined?(Mongoid) or defined?(MongoMapper)
  require File.join(File.dirname(__FILE__), "mongo_joinable/core_ext/string")
  require File.join(File.dirname(__FILE__), "mongo_joinable/joined")
  require File.join(File.dirname(__FILE__), "mongo_joinable/joiner")
  require File.join(File.dirname(__FILE__), "../app/models/join")
  require File.join(File.dirname(__FILE__), "mongo_joinable/features/history")
end