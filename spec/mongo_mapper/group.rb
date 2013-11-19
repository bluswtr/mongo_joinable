class Group
  include MongoMapper::Document
  include Mongo::Joinable::Joined
  include Mongo::Joinable::History
end