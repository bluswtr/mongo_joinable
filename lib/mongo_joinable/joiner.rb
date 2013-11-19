module Mongo
  module Joinable
    module Joiner
     extend ActiveSupport::Concern

     included do |base|
       if defined?(Mongoid)
         base.has_many :joinees, :class_name => "Join", :as => :joining, :dependent => :destroy
       elsif defined?(MongoMapper)
         base.many :joinees, :class_name => "Join", :as => :joining, :dependent => :destroy
       end
     end

     module ClassMethods

       # get certain model's joiners of this type
       #
       # Example:
       #   >> @jim = User.new
       #   >> @ruby = Group.new
       #   >> @jim.save
       #   >> @ruby.save
       #
       #   >> @jim.join(@ruby)
       #   >> User.joiners_of(@ruby)
       #   => [@jim]
       #
       #   Arguments:
       #     model: instance of some joinable model

       def joiners_of(model)
         model.joiners_by_type(self.name)
       end

       # 4 methods in this function
       #
       # Example:
       #   >> User.with_max_joinees
       #   => [@jim]
       #   >> User.with_max_joinees_by_type('group')
       #   => [@jim]

       ["max", "min"].each do |s|
         define_method(:"with_#{s}_joinees") do
           join_array = self.all.to_a.sort! { |a, b| a.joinees_count <=> b.joinees_count }
           num = join_array[-1].joinees_count
           join_array.select { |c| c.joinees_count == num }
         end

         define_method(:"with_#{s}_joinees_by_type") do |*args|
           join_array = self.all.to_a.sort! { |a, b| a.joinees_count_by_type(args[0]) <=> b.joinees_count_by_type(args[0]) }
           num = join_array[-1].joinees_count_by_type(args[0])
           join_array.select { |c| c.joinees_count_by_type(args[0]) == num }
         end
       end

       #def method_missing(name, *args)
       #  if name.to_s =~ /^with_(max|min)_joinees$/i
       #    join_array = self.all.to_a.sort! { |a, b| a.joinees_count <=> b.joinees_count }
       #    if $1 == "max"
       #      max = join_array[-1].joinees_count
       #      join_array.select { |c| c.joinees_count == max }
       #    elsif $1 == "min"
       #      min = join_array[0].joinees_count
       #      join_array.select { |c| c.joinees_count == min }
       #    end
       #  elsif name.to_s =~ /^with_(max|min)_joinees_by_type$/i
       #    join_array = self.all.to_a.sort! { |a, b| a.joinees_count_by_type(args[0]) <=> b.joinees_count_by_type(args[0]) }
       #    if $1 == "max"
       #      max = join_array[-1].joinees_count_by_type(args[0])
       #      join_array.select { |c| c.joinees_count_by_type(args[0]) == max }
       #    elsif $1 == "min"
       #      min = join_array[0].joinees_count
       #      join_array.select { |c| c.joinees_count_by_type(args[0]) == min }
       #    end
       #  else
       #    super
       #  end
       #end

     end

     # see if this model is joiner of some model
     #
     # Example:
     #   >> @jim.joiner_of?(@ruby)
     #   => true

     def joiner_of?(model)
       0 < self.joinees.by_model(model).limit(1).count * model.joiners.by_model(self).limit(1).count
     end

     # return true if self is joining some models
     #
     # Example:
     #   >> @jim.joining?
     #   => true

     def joining?
       0 < self.joinees.length
     end

     # get all the joinees of this model, same with classmethod joinees_of
     #
     # Example:
     #   >> @jim.all_joinees
     #   => [@ruby]

     def all_joinees
       rebuild_instances(self.joinees)
     end

     # get all the joinees of this model in certain type
     #
     # Example:
     #   >> @ruby.joinees_by_type("group")
     #   => [@ruby]

     def joinees_by_type(type)
       rebuild_instances(self.joinees.by_type(type))
     end

     # join some model

     def join(*models, &block)
       if block_given?
         models.delete_if { |model| !yield(model) }
       end

       models.each do |model|
         unless model == self or self.joiner_of?(model) or model.joinee_of?(self)
           model.joiners.create!(:f_type => self.class.name, :f_id => self.id.to_s)
           self.joinees.create!(:f_type => model.class.name, :f_id => model.id.to_s)

           model.joined_history << self.class.name + '_' + self.id.to_s if model.respond_to? :joined_history
           self.join_history << model.class.name + '_' + model.id.to_s if self.respond_to? :join_history

           model.save
           self.save
         end
       end
     end

     # unjoin some model

     def unjoin(*models, &block)
       if block_given?
         models.delete_if { |model| !yield(model) }
       end

       models.each do |model|
         unless model == self or !self.joiner_of?(model) or !model.joinee_of?(self)
           model.joiners.by_model(self).first.destroy
           self.joinees.by_model(model).first.destroy
         end
       end
     end

     # unjoin all

     def unjoin_all
       unjoin(*self.all_joinees)
     end

     # get the number of joinees
     #
     # Example:
     #   >> @jim.joiners_count
     #   => 1

     def joinees_count
       self.joinees.count
     end

     # get the number of joiners in certain type
     #
     # Example:
     #   >> @ruby.joiners_count_by_type("user")
     #   => 1

     def joinees_count_by_type(type)
       self.joinees.by_type(type).count
     end

     # return if there is any common joinees
     #
     # Example:
     #   >> @jim.common_joinees?(@tom)
     #   => true

     def common_joinees?(model)
       0 < (rebuild_instances(self.joinees) & rebuild_instances(model.joinees)).length
     end

     # get common joinees with some model
     #
     # Example:
     #   >> @jim.common_joinees_with(@tom)
     #   => [@ruby]

     def common_joinees_with(model)
       rebuild_instances(self.joinees) & rebuild_instances(model.joinees)
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
