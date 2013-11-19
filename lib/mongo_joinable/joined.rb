module Mongo
  module Joinable
    module Joined
      extend ActiveSupport::Concern

      included do |base|
        if defined?(Mongoid)
          base.has_many :joiners, :class_name => "Join", :as => :joinable, :dependent => :destroy
        elsif defined?(MongoMapper)
          base.many :joiners, :class_name => "Join", :as => :joinable, :dependent => :destroy
        end
      end

      module ClassMethods

        # get certain model's joinees of this type
        #
        # Example:
        #   >> @jim = User.new
        #   >> @ruby = Group.new
        #   >> @jim.save
        #   >> @ruby.save
        #
        #   >> @jim.join(@ruby)
        #   >> User.joinees_of(@jim)
        #   => [@ruby]
        #
        #   Arguments:
        #     model: instance of some joinable model

        def joinees_of(model)
          model.joinees_by_type(self.name)
        end

        # 4 methods in this function
        #
        # Example:
        #   >> Group.with_max_joiners
        #   => [@ruby]
        #   >> Group.with_max_joiners_by_type('user')
        #   => [@ruby]

        ["max", "min"].each do |s|
          define_method(:"with_#{s}_joiners") do
            join_array = self.all.to_a.sort! { |a, b| a.joiners_count <=> b.joiners_count }
            num = join_array[-1].joiners_count
            join_array.select { |c| c.joiners_count == num }
          end

          define_method(:"with_#{s}_joiners_by_type") do |*args|
            join_array = self.all.to_a.sort! { |a, b| a.joiners_count_by_type(args[0]) <=> b.joiners_count_by_type(args[0]) }
            num = join_array[-1].joiners_count_by_type(args[0])
            join_array.select { |c| c.joiners_count_by_type(args[0]) == num }
          end
        end

        #def method_missing(name, *args)
        #  if name.to_s =~ /^with_(max|min)_joiners$/i
        #    join_array = self.all.to_a.sort! { |a, b| a.joiners_count <=> b.joiners_count }
        #    if $1 == "max"
        #      max = join_array[-1].joiners_count
        #      join_array.select { |c| c.joiners_count == max }
        #    elsif $1 == "min"
        #      min = join_array[0].joiners_count
        #      join_array.select { |c| c.joiners_count == min }
        #    end
        #  elsif name.to_s =~ /^with_(max|min)_joiners_by_type$/i
        #    join_array = self.all.to_a.sort! { |a, b| a.joiners_count_by_type(args[0]) <=> b.joiners_count_by_type(args[0]) }
        #    if $1 == "max"
        #      max = join_array[-1].joiners_count_by_type(args[0])
        #      join_array.select { |c| c.joiners_count_by_type(args[0]) == max }
        #    elsif $1 == "min"
        #      min = join_array[0].joiners_count
        #      join_array.select { |c| c.joiners_count_by_type(args[0]) == min }
        #    end
        #  else
        #    super
        #  end
        #end

      end

      # see if this model is joinee of some model
      #
      # Example:
      #   >> @ruby.joinee_of?(@jim)
      #   => true

      def joinee_of?(model)
        0 < self.joiners.by_model(model).limit(1).count * model.joinees.by_model(self).limit(1).count
      end

      # return true if self is joined by some models
      #
      # Example:
      #   >> @ruby.joined?
      #   => true

      def joined?
        0 < self.joiners.length
      end

      # get all the joiners of this model, same with classmethod joiners_of
      #
      # Example:
      #   >> @ruby.all_joiners
      #   => [@jim]

      def all_joiners(page = nil, per_page = nil)
        pipeline = [
          { '$project' =>
            { _id: 0,
              f_id: 1,
              joinable_id: 1,
              joinable_type: 1
            }
          },
          {
            '$match' => {
              'joinable_id' => self.id,
              'joinable_type' => self.class.name.split('::').last
            }
          }
        ]

        if page && per_page
          pipeline << { '$skip' => (page * per_page) }
          pipeline << { '$limit' => per_page }
        end

        pipeline << { '$project' => { f_id: 1 } }

        command = {
          aggregate: 'joins',
          pipeline: pipeline
        }

        if defined?(Mongoid)
          db = Mongoid.default_session
        elsif defined?(MongoMapper)
          db = MongoMapper.database
        end

        users_hash = db.command(command)['result']

        ids = users_hash.map {|e| e['f_id']}

        User.where(id: { '$in' => ids }).all.entries
      end

      def unjoined(*models, &block)
        if block_given?
          models.delete_if { |model| !yield(model) }
        end

        models.each do |model|
          unless model == self or !self.joinee_of?(model) or !model.joiner_of?(self)
            model.joinees.by_model(self).first.destroy
            self.joiners.by_model(model).first.destroy
          end
        end
      end

      # unjoin all

      def unjoined_all
        unjoined(*self.all_joiners)
      end

      # get all the joiners of this model in certain type
      #
      # Example:
      #   >> @ruby.joiners_by_type("user")
      #   => [@jim]

      def joiners_by_type(type)
        rebuild_instances(self.joiners.by_type(type))
      end

      # get the number of joiners
      #
      # Example:
      #   >> @ruby.joiners_count
      #   => 1

      def joiners_count
        self.joiners.count
      end

      # get the number of joiners in certain type
      #
      # Example:
      #   >> @ruby.joiners_count_by_type("user")
      #   => 1

      def joiners_count_by_type(type)
        self.joiners.by_type(type).count
      end

      # return if there is any common joiners
      #
      # Example:
      #   >> @ruby.common_joinees?(@python)
      #   => true

      def common_joiners?(model)
        0 < (rebuild_instances(self.joiners) & rebuild_instances(model.joiners)).length
      end

      # get common joiners with some model
      #
      # Example:
      #   >> @ruby.common_joiners_with(@python)
      #   => [@jim]

      def common_joiners_with(model)
        rebuild_instances(self.joiners) & rebuild_instances(model.joiners)
      end

      private
        def rebuild_instances(joins) #:nodoc:
          joins.group_by(&:f_type).inject([]) { |r, (k, v)| r += k.constantize.find(v.map(&:f_id)).to_a }
          #join_list = []
          #joins.each do |join|
          #  join_list << join.f_type.constantize.find(join.f_id)
          #end
          #join_list
        end
    end
  end
end
