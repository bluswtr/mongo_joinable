class ChildUser
  include Mongoid::Document
  include Mongo::Joinable::Joined
  include Mongo::Joinable::Joiner
  include Mongo::Joinable::History
end