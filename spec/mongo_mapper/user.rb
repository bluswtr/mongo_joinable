class User
  include MongoMapper::Document
  include Mongo::Joinable::Joined
  include Mongo::Joinable::Joiner
  include Mongo::Joinable::History
end