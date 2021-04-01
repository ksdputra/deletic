# frozen_string_literal: true

require "active_record"

require "deletic/version"
require "deletic/errors"
require "deletic/base"

ActiveSupport.on_load(:active_record) do
  class ActiveRecord::Base
    def self.acts_as_deletic(options={})
      define_model_callbacks :soft_destroy
      define_model_callbacks :restore

      class_attribute :deletic_column, :skip_ar_callbacks
      self.deletic_column = options[:column] || :deleted_at
      self.skip_ar_callbacks = options[:skip_ar_callbacks].nil? ? true : false

      if options[:without_default_scope]
        scope :kept, ->{ where(deletic_column => nil) }
        scope :soft_deleted, ->{ where.not(deletic_column => nil) }
        scope :with_soft_deleted, ->{ unscope(where: deletic_column) }
      else
        default_scope { where(deletic_column => nil) }
        scope :kept, ->{}
        scope :soft_deleted, ->{ unscope(where: deletic_column).where.not(deletic_column => nil) }
        scope :with_soft_deleted, ->{ unscope(where: deletic_column) }
      end

      include Deletic::Base
    end
  end
end