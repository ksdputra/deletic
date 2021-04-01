# frozen_string_literal: true

module Deletic
  # = Deletic Errors
  #
  # Generic exception class.
  class DeleticError < StandardError
  end

  # Raised by {Deletic::Base#soft_delete!}
  class RecordNotDeleted < DeleticError
    attr_reader :record

    def initialize(message = nil, record = nil)
      @record = record
      super(message)
    end
  end

  # Raised by {Deletic::Base#restore!}
  class RecordNotRestored < DeleticError
    attr_reader :record

    def initialize(message = nil, record = nil)
      @record = record
      super(message)
    end
  end
end