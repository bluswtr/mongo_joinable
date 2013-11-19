module Mongo
  module Joinable
    module History
      extend ActiveSupport::Concern

      included do |base|
        if base.include?(Mongo::Joinable::Joiner)
          if defined?(Mongoid)
            base.field :join_history, :type => Array, :default => []
          elsif defined?(MongoMapper)
            base.key :join_history, :type => Array, :default => []
          end
        end

        if base.include?(Mongo::Joinable::Joined)
          if defined?(Mongoid)
            base.field :joined_history, :type => Array, :default => []
          elsif defined?(MongoMapper)
            base.key :joined_history, :type => Array, :default => []
          end
        end
      end

      module ClassMethods
 #       def clear_history!
 #         self.all.each { |m| m.unset(:join_history) }
 #         self.all.each { |m| m.unset(:joined_history) }
 #       end
      end

      def clear_history!
        clear_join_history!
        clear_joined_histroy!
      end

      def clear_join_history!
        self.update_attribute(:join_history, []) if has_join_history?
      end

      def clear_joined_histroy!
        self.update_attribute(:joined_history, []) if has_joined_history?
      end

      def ever_join
        rebuild(self.join_history) if has_join_history?
      end

      def ever_joined
        rebuild(self.joined_history) if has_joined_history?
      end

      def ever_join?(model)
        self.join_history.include?(model.class.name + "_" + model.id.to_s) if has_join_history?
      end

      def ever_joined?(model)
        self.joined_history.include?(model.class.name + "_" + model.id.to_s) if has_joined_history?
      end

      private
        def has_join_history?
          self.respond_to? :join_history
        end

        def has_joined_history?
          self.respond_to? :joined_history
        end

        def rebuild(ary)
          ary.group_by { |x| x.split("_").first }.
              inject([]) { |n,(k,v)| n += k.constantize.
              find(v.map { |x| x.split("_").last}) }
        end
    end
  end
end