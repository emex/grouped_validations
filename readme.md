#Grouped Validations

[![Build Status](https://travis-ci.org/krancour/grouped_validations.svg?branch=development)](https://travis-ci.org/krancour/grouped_validations)

Allows you to define ActiveModel validation groups for more control over what validations you want to run.

This can be useful for multi-page forms or wizard style data entry.

This project has been forked from "peterbeers," who forked the project from Adama Meehan.  Adam deserves most of the credit.  peterbeers' fork made the gem compatible with Rails 4.0.x.  This fork aims to establish Rails 4.1.x compaitiblity as well as a test matrix for validating the project against various versions of Ruby and Rails.

Compatible with (at least) Ruby:

* 1.9.3
* 2.0.0
* 2.1.1

Compatible with Rails:

* 4.0.x.

This is _not_ yet compatible with Rails 4.1.x.

##Installation

Just install the gem with bundler as usual:

    gem install grouped_validations        

##Usage

Call `validation_group`, passing it a name and a block of code.  Within the block, define validations as you normally would:

    class Person < ActiveRecord::Base

      validation_group :name do
        validates :first_name, presence: true
        validates :last_name, presence: true
      end

      validates :sex, presence: true

    end

You can still define validations outside validation groups.

To check for errors for only a certain group of validations:

    p = Person.new
    p.group_valid?(:name) # => false
    p.first_name = 'John'
    p.last_name = 'Smith'
    p.group_valid?(:name) # => true

If you run the normal `valid?` method, all validations, inside and outside validation groups, will be run:

    p.valid? # => false because sex is not present

You can also check validation for multiple groups:

    p.groups_valid?(:group1, :group2)

To define validation blocks, just use the respective group validation method, like so:

    class Person < ActiveRecord::Base
  
      validation_group :name do
        validates :first_name, presence: true
        validates :last_name, presence: true
      end

      validate_name           {|r| # something custom on save }
      validate_name_on_create {|r| # something custom on create }
      validate_name_on_update {|r| # something custom on update }
  
    end

##Group Options

`validation_group` can be used to supply options to multiple validations, similar to the `with_options` method:

If you pass in an options hash, those options will be applied to each validation method in the block:

    validation_group :name, :if => :ready? do
      validates :first_name, presence: true
      validates :last_name, presence: true
    end

This is effectively the same as doing the following, but is more DRY:

    validation_group :name do
      validates :first_name, presence: true, :if => :ready?
      validates :last_name, presence: true, :if => :ready?
    end

If you set an option for a specific validation method, it will override the group options:

  validation_group :name, :if => :ready? do
    validates :first_name, presence: true
    validates :last_name, presence: true, :if => { |r| !r.popstar? }
  end

The `last_name` attribute will be required unless the person is a popstar.

The options should work for any validation method which calls the `validate` class method internally. This includes all the default validations.

For more precise control over when groups options are merged with individual validation option, you can pass an argument to the block and use it in the same manner as `with_options`.  Then, only those validation methods called on the argument will have the group options merged in:

    validation_group :name, :if => :ready? do |options|
      # Options merged
      options.validates :first_name, presence: true

      # No options merged
      validates :last_name, presence: true
    end

##Grouped Errors

The errors for the model can be returned as a hash with the group names as the keys. If you have a number of groups, you can deal with the error messages in specific ways per group:

    validation_group :name do
      validates :first_name, presence: true
      validates :last_name, presence: true
    end

    validates :sex, presence: true

To access all errors outside of a validation group, use nil as the key:

    person.grouped_errors[nil]

Use the group name as the key for all errors in a particular group:

    person.grouped_errors[:name]

Be aware that the validations will all be run at this time. If you have just called `valid?`, then the same validations will be re-run and the current state of the object is used. You may want to consider this if your validations are expensive, time sensitive, or if you have changed the object since last calling `valid?`.

You can use the `grouped_errors` method instead of `valid?` to check on a valid object like so:

    # Validations all run
    if person.grouped_errors.empty?
      # object is valid
    end

##Credits

* Adam Meehan (http://github.com/adzap)
* "peterbeers" (http://github.com/peterbeers)
* Kent Rancourt (http://github.com/krancour)

Released under the MIT license.