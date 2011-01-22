module GroupedValidations

  module ClassMethods

    def validation_group(group, &block)
      raise "The validation_group method requires a block" unless block_given?

      unless self.include?(GroupedValidations::InstanceMethods)
        include GroupedValidations::InstanceMethods
      end

      self.validation_groups ||= []

      unless self.validation_groups.include?(group)
        self.validation_groups << group
        define_group_validation_callbacks(group)
      end

      @current_validation_group = group
      class_eval &block
      @current_validation_group = nil
    end

    def default_validation_group(&block)
      raise "The default_validation_group method requires a block" unless block_given?
      self.validation_group_selector = block
    end
    alias default_validation_groups default_validation_group

  end

  module InstanceMethods
    def self.included(base)
      base.alias_method_chain :valid?, :groups
      base.class_eval do
        class << self
          if ActiveRecord::VERSION::MAJOR < 3
            alias_method_chain :validation_method, :groups
          else
            alias_method_chain :validate, :groups
          end
        end
      end
    end

    def valid_with_groups?(context=nil)
      groups = validation_group_selector ? validation_group_selector.call : :all
      groups_valid_with_context?(groups, context)
    end

    def groups_valid?(*groups)
      errors.clear
      groups_valid_with_context?(groups)
    end
    alias group_valid? groups_valid?

    def groups_valid_with_context?(groups, context=nil)
      groups = groups.present? ? Array.wrap(groups) : []
      groups = [:global].concat(validation_groups || []) if groups.include?(:all)
      groups.each do |group|
        if group == :global
          run_global_validation_callbacks context
        else
          raise "Validation group '#{group}' not defined" unless validation_groups.include?(group)
          run_group_validation_callbacks group
        end
      end
      errors.empty?
    end

  end

end

ActiveRecord::Base.class_eval do
  extend GroupedValidations::ClassMethods
  class_inheritable_accessor :validation_groups
  class_inheritable_accessor :validation_group_selector
end

if ActiveRecord::VERSION::MAJOR < 3
  require 'grouped_validations/active_record'
else
  require 'grouped_validations/active_model'
end
