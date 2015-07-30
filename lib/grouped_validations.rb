require 'active_model/validations'
require 'grouped_validations/active_model'

module GroupedValidations
  extend ActiveSupport::Concern

  included do
    class_attribute :validation_groups
    self.validation_groups = []
    class_attribute :validation_group_selector
  end

  module ClassMethods

    def validate(*args, &block)
      return super unless @_current_validation_group

      options = args.extract_options!.dup
      unless @_current_validation_group[:with_options]
        options.reverse_merge!(@_current_validation_group.except(:name))
      end

      if options.key?(:on)
        options = options.dup
        options[:if] = Array.wrap(options[:if])
        options[:if] << "validation_context == :#{options[:on]}"
      end
      args << options
      set_callback(:"validate_#{@_current_validation_group[:name]}", *args, &block)
    end

    def _define_group_validation_callbacks(group)
      define_callbacks :"validate_#{group}", :scope => 'validate'
    end

  end

  def valid?(context=nil)
    errors.clear
    groups = select_validation_groups
    super if groups.include?(:global)
    validate_groups(groups, :context => context, :skip_global => true)
    errors.empty?
  end

  def groups_valid?(*groups)
    options = groups.extract_options!
    errors.clear
    groups = select_validation_groups(groups)
    validate_groups(groups, options)
    errors.empty?
  end
  alias_method :group_valid?, :groups_valid?

  def select_validation_groups(groups=nil)
    if !groups.present?
      groups = validation_group_selector ? validation_group_selector.call(self) : :all
    end
    groups = Array.wrap(groups)
    groups = [:global].concat(validation_groups || []) if groups.include?(:all)
    groups
  end

  def validate_groups(groups, options)
    groups.each do |group|
      if group == :global
        _run_global_validation_callbacks unless options[:skip_global]
      else
        raise "Validation group '#{group}' not defined" unless validation_groups.include?(group)
        _run_group_validation_callbacks(group, options[:context])
      end
    end
  end

  def _run_global_validation_callbacks
    run_validations!
  end

  def _run_group_validation_callbacks(group, context=nil)
    with_validation_context(context) do
      run_callbacks(:"validate_#{group}")
    end
  end

  def with_validation_context(context)
    context ||= (persisted? ? :update : :create)
    current_context, self.validation_context = validation_context, context
    yield
  ensure
    self.validation_context = current_context
  end

end
