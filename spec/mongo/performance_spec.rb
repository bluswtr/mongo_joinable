require "spec_helper"
require "benchmark"

users = []
1000.times { users << User.create! }
group = Group.create!

users.each { |u| u.join(group) }

Benchmark.bmbm do |x|
  x.report("before") { group.joiners }
end

RSpec.configure do |c|
  c.before(:all)  { DatabaseCleaner.strategy = :truncation }
  c.before(:each) { DatabaseCleaner.clean }
end
