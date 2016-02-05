module Nudge
  class Response
    attr_reader :success, :message

    def initialize(success, message)
      @success = success
      @message = message
    end
  end
end
