require 'spec_helper'

describe Mongo::Joinable do
  describe User do
    let!(:u) { User.create! }

    context "begins" do
      let!(:v) { User.create! }
      let!(:w) { User.create! }
      let!(:g) { Group.create! }

      it "joining a user" do
        u.join(v, g)

        u.joining?.should be_true
        v.joined?.should be_true
        g.joined?.should be_true

        u.joiner_of?(v).should be_true
        v.joinee_of?(u).should be_true

        u.all_joinees.should == [v, g]
        v.all_joiners.should == [u]

        u.joinees_by_type("user").should == [v]
        v.joiners_by_type("user").should == [u]

        u.joinees_count.should == 2
        v.joiners_count.should == 1

        u.joinees_count_by_type("user").should == 1
        v.joiners_count_by_type("user").should == 1

        u.ever_join.should =~ [v, g]
        v.ever_joined.should == [u]

        u.ever_join?(v).should be_true
        u.ever_join?(g).should be_true
        v.ever_joined?(u).should be_true

        u.common_joinees?(v).should be_false
        v.common_joiners?(u).should be_false
        u.common_joinees_with(v).should == []
        v.common_joiners_with(u).should == []

        User.with_max_joinees.should == [u]
        User.with_max_joiners.should == [v]
        User.with_max_joinees_by_type('user').should == [u]
        User.with_max_joiners_by_type('user').should == [v]
      end

      it "unjoining" do
        u.unjoin_all

        u.joiner_of?(v).should be_false
        v.joinee_of?(u).should be_false

        u.all_joinees.should == []
        v.all_joiners.should == []

        u.joinees_by_type("user").should == []
        v.joiners_by_type("user").should == []

        u.joinees_count.should == 0
        v.joiners_count.should == 0

        u.joinees_count_by_type("user").should == 0
        v.joiners_count_by_type("user").should == 0
      end

      it "joining a group" do
        u.join(g)

        u.joiner_of?(g).should be_true
        g.joinee_of?(u).should be_true

        u.all_joinees.should == [g]
        g.all_joiners.should == [u]

        u.joinees_by_type("group").should == [g]
        g.joiners_by_type("user").should == [u]

        u.joinees_count.should == 1
        g.joiners_count.should == 1

        u.joinees_count_by_type("group").should == 1
        g.joiners_count_by_type("user").should == 1

        u.join(v)

        u.ever_join.should =~ [g, v]
        g.ever_joined.should == [u]

        u.clear_join_history!
        u.ever_join.should == []

        g.clear_history!
        g.ever_joined.should == []

        u.common_joinees?(v).should be_false
        v.common_joiners?(g).should be_true
        u.common_joinees_with(v).should == []
        v.common_joiners_with(g).should == [u]

        User.with_max_joinees.should == [u]
        Group.with_max_joiners.should == [g]
        User.with_max_joinees_by_type('group').should == [u]
        Group.with_max_joiners_by_type('user').should == [g]
      end

      it "unjoining a group" do
        u.unjoin(g)

        u.joiner_of?(g).should be_false
        g.joinee_of?(u).should be_false

        u.all_joinees.should == []
        g.all_joiners.should == []

        u.joinees_by_type("group").should == []
        g.joiners_by_type("group").should == []

        u.joinees_count.should == 0
        g.joiners_count.should == 0

        u.joinees_count_by_type("group").should == 0
        g.joiners_count_by_type("group").should == 0
      end
    end
  end

  describe Group do
    let!(:g) { Group.create! }
    context "begins" do
      let(:v) { User.create! }
      let(:w) { User.create! }
      let(:u) { User.create! }

      it "another way to unjoin a group" do
        u.join(g)
        v.join(g)
        w.join(g)

        g.all_joiners.should =~ [v,u,w]

        w.joiner_of?(g).should be_true
        g.joinee_of?(w).should be_true

        #g.unjoined(w)

        u.joiner_of?(g).should be_true
        g.joinee_of?(u).should be_true

        v.joiner_of?(g).should be_true
        g.joinee_of?(v).should be_true

        #g.all_joiners.should =~ [v,u]

        g.unjoined_all

        g.all_joiners == []
      end

      it "another way to unjoin a group" do
        u.join(g)
        g.unjoined(u)
      end

      it "another way to unjoin a group" do
        g.all_joiners.should == []
      end
    end
  end

  describe User do
    let(:u) { User.create! }

    context "begins" do
      let(:v) { User.create! }
      let(:w) { User.create! }
      let(:g) { Group.create! }

      it "block test" do
        u.join(v, w, g) {|m| m.class == User}

        u.all_joinees.should =~ [v, w]
      end

      it "block test unjoin" do
        u.unjoin(v, w, g) {|m| m.joinee_of? u}

        u.all_joinees.should == []
      end
    end
  end

  describe ChildUser do
     let(:v) { ChildUser.create! }

    context "begins" do
      let(:u) { User.create! }
      let(:w) { User.create! }
      let(:g) { Group.create! }

      it "inherited model test" do
        u.join(v, w, g) {|m| m.class == User}

        u.all_joinees.should == [w]

        u.joinees_by_type("user") == [w]

        w.joiners_by_type("child_user") == [u]
        w.joiners_by_type("childUser") == [u]
        w.joiners_by_type("ChildUser") == [u]
      end
    end
  end
end

