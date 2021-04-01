# frozen_string_literal: true

module Deletic
  # Handles soft deletes of records.
  #
  # Options:
  #
  # - :deletic_column - The columns used to track soft delete, defaults to `:deleted_at`.
  module Base
    extend ActiveSupport::Concern

    # :nodoc:
    module ClassMethods
      # Soft Deletes the records by instantiating each
      # record and calling its {#soft_delete} method.
      # Each object's callbacks are executed.
      # Returns the collection of objects that were soft deleted.
      #
      # Note: Instantiation, callback execution, and update of each
      # record can be time consuming when you're soft deleting many records at
      # once. It generates at least one SQL +UPDATE+ query per record (or
      # possibly more, to enforce your callbacks). If you want to soft delete many
      # rows quickly, without concern for their associations or callbacks, use
      # #update_all(deleted_at: Time.current) instead.
      #
      # ==== Examples
      #
      #   Person.where(age: 0..18).soft_delete_all
      def soft_delete_all
        kept.each(&:soft_delete)
      end

      # Soft Deletes the records by instantiating each
      # record and calling its {#soft_delete!} method.
      # Each object's callbacks are executed.
      # Returns the collection of objects that were soft deleted.
      #
      # Note: Instantiation, callback execution, and update of each
      # record can be time consuming when you're soft deleting many records at
      # once. It generates at least one SQL +UPDATE+ query per record (or
      # possibly more, to enforce your callbacks). If you want to soft delete many
      # rows quickly, without concern for their associations or callbacks, use
      # #update_all!(deleted_at: Time.current) instead.
      #
      # ==== Examples
      #
      #   Person.where(age: 0..18).soft_delete_all!
      def soft_delete_all!
        kept.each(&:soft_delete!)
      end

      # Restores the records by instantiating each
      # record and calling its {#restore} method.
      # Each object's callbacks are executed.
      # Returns the collection of objects that were restored.
      #
      # Note: Instantiation, callback execution, and update of each
      # record can be time consuming when you're restoring many records at
      # once. It generates at least one SQL +UPDATE+ query per record (or
      # possibly more, to enforce your callbacks). If you want to restore many
      # rows quickly, without concern for their associations or callbacks, use
      # #update_all(deleted_at: nil) instead.
      #
      # ==== Examples
      #
      #   Person.where(age: 0..18).restore_all
      def restore_all
        soft_deleted.each(&:restore)
      end

      # Restores the records by instantiating each
      # record and calling its {#restore!} method.
      # Each object's callbacks are executed.
      # Returns the collection of objects that were restored.
      #
      # Note: Instantiation, callback execution, and update of each
      # record can be time consuming when you're restoring many records at
      # once. It generates at least one SQL +UPDATE+ query per record (or
      # possibly more, to enforce your callbacks). If you want to restore many
      # rows quickly, without concern for their associations or callbacks, use
      # #update_all!(deleted_at: nil) instead.
      #
      # ==== Examples
      #
      #   Person.where(age: 0..18).restore_all!
      def restore_all!
        soft_deleted.each(&:restore!)
      end
    end

    # @return [Boolean] true if this record has been soft deleted, otherwise false
    def soft_deleted?
      self[self.class.deletic_column].present?
    end

    # @return [Boolean] false if this record has been soft deleted, otherwise true
    def kept?
      !soft_deleted?
    end

    # Soft Delete the record in the database
    #
    # @return [Boolean] true if successful, otherwise false
    def soft_delete
      return false if soft_deleted?
      run_callbacks(:soft_delete) do
        update_attribute(self.class.deletic_column, Time.current)
      end
    end

    # Soft Delete the record in the database
    #
    # There's a series of callbacks associated with #soft_delete!. If the
    # <tt>before_soft_delete</tt> callback throws +:abort+ the action is cancelled
    # and #soft_delete! raises {Deletic::RecordNotDeleted}.
    #
    # @return [Boolean] true if successful
    # @raise {Deletic::RecordNotDeleted}
    def soft_delete!
      soft_delete || _raise_record_not_deleted
    end

    # Restore the record in the database
    #
    # @return [Boolean] true if successful, otherwise false
    def restore
      return false unless soft_deleted?
      run_callbacks(:restore) do
        update_attribute(self.class.deletic_column, nil)
      end
    end

    # Restore the record in the database
    #
    # There's a series of callbacks associated with #restore!. If the
    # <tt>before_restore</tt> callback throws +:abort+ the action is cancelled
    # and #restore! raises {Deletic::RecordNotRestored}.
    #
    # @return [Boolean] true if successful
    # @raise {Deletic::RecordNotRestored}
    def restore!
      restore || _raise_record_not_restored
    end

    private

    def _raise_record_not_deleted
      raise ::Deletic::RecordNotDeleted.new("Failed to soft delete the record", self)
    end

    def _raise_record_not_restored
      raise ::Deletic::RecordNotRestored.new("Failed to restore the record", self)
    end
  end
end