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
      # record and calling its {#soft_destroy} method.
      # Each object's callbacks are executed.
      # Returns the collection of objects that were soft deleted.
      #
      # Note: Instantiation, callback execution, and update of each
      # record can be time consuming when you're soft deleting many records at
      # once. It generates at least one SQL +UPDATE+ query per record (or
      # possibly more, to enforce your callbacks). If you want to soft delete many
      # rows quickly, without concern for their associations or callbacks, use
      # #soft_delete_all instead.
      #
      # ==== Examples
      #
      #   Person.where(age: 0..18).soft_destroy_all
      def soft_destroy_all
        kept.each(&:soft_destroy)
      end

      # Soft Deletes the records by instantiating each
      # record and calling its {#soft_destroy!} method.
      # Each object's callbacks are executed.
      # Returns the collection of objects that were soft deleted.
      #
      # Note: Instantiation, callback execution, and update of each
      # record can be time consuming when you're soft deleting many records at
      # once. It generates at least one SQL +UPDATE+ query per record (or
      # possibly more, to enforce your callbacks). If you want to soft delete many
      # rows quickly, without concern for their associations or callbacks, use
      # #soft_delete_all instead.
      #
      # ==== Examples
      #
      #   Person.where(age: 0..18).soft_destroy_all!
      def soft_destroy_all!
        kept.each(&:soft_destroy!)
      end

      # Soft Deletes the records by using #update_all
      # No callback is executed.
      # Returns the count of objects that were soft deleted.
      #
      # ==== Examples
      #
      #   Person.where(age: 0..18).soft_delete_all
      def soft_delete_all
        update_all(deleted_at: Time.current)
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
      # #reconstruct_all instead.
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
      # #reconstruct_all instead.
      #
      # ==== Examples
      #
      #   Person.where(age: 0..18).restore_all!
      def restore_all!
        soft_deleted.each(&:restore!)
      end

      # Restores the records by instantiating each
      # record and calling its {#restore!} method.
      # Each object's callbacks are executed.
      # Returns the count of objects that were restored.
      #
      # ==== Examples
      #
      #   Person.where(age: 0..18).reconstruct_all!
      def reconstruct_all
        update_all(deleted_at: nil)
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

    # Soft Destroy the record in the database
    #
    # @return [Boolean] true if successful, otherwise false
    def soft_destroy
      return false if soft_deleted?

      run_callbacks(:soft_destroy) do
        if skip_ar_callbacks
          update_column(self.class.deletic_column, Time.current)
        else
          update_attribute(self.class.deletic_column, Time.current)
        end
      end
    end

    # Soft Destroy the record in the database
    #
    # There's a series of callbacks associated with #soft_destroy!. If the
    # <tt>before_soft_destroy</tt> callback throws +:abort+ the action is cancelled
    # and #soft_destroy! raises {Deletic::RecordNotDeleted}.
    #
    # @return [Boolean] true if successful
    # @raise {Deletic::RecordNotDeleted}
    def soft_destroy!
      soft_destroy || _raise_record_not_deleted
    end

    # Soft Delete the record in the database
    # The row is simply removed with an SQL UPDATE statement on the record's primary key,
    # and no callbacks are executed.
    #
    # To enforce the object's before_destroy and after_destroy callbacks 
    # or any :dependent association options, use #soft_destroy.
    #
    # @return [Boolean] true if successful, otherwise false
    def soft_delete
      return false if soft_deleted?

      if skip_ar_callbacks
        update_column(self.class.deletic_column, Time.current)
      else
        update_attribute(self.class.deletic_column, Time.current)
      end
    end

    # Restore the record in the database
    #
    # @return [Boolean] true if successful, otherwise false
    def restore
      return false unless soft_deleted?

      run_callbacks(:restore) do
        if skip_ar_callbacks
          update_column(self.class.deletic_column, nil)
        else
          update_attribute(self.class.deletic_column, nil)
        end
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

    # Restore the record in the database
    # The row is simply removed with an SQL UPDATE statement on the record's primary key,
    # and no callbacks are executed.
    #
    # To enforce the object's before_restore and after_restore callbacks 
    # or any :dependent association options, use #restore.
    #
    # @return [Boolean] true if successful, otherwise false
    def reconstruct
      return false unless soft_deleted?

      if skip_ar_callbacks
        update_column(self.class.deletic_column, nil)
      else
        update_attribute(self.class.deletic_column, nil)
      end
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