class Group
  include Mongoid::Document
  include Mongo::Joinable::Joined
  include Mongo::Joinable::History
end