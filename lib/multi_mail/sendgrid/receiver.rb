module MultiMail
  module Receiver
    class SendGrid < MultiMail::Service
      include MultiMail::Receiver::Base

      #requires :

      # @param [Hash] options required and optional arguments
      def initialize(options = {})
        super
      end

      # @param [Hash] params the content of SendGrid's webhook
      # @return [Boolean] whether the request originates from SendGrid
      def valid?(params)
        true
      end

      # @param [Mail::Message] message a message
      # @return [Boolean] whether the message is spam
      def spam?(message)
        false
      end

      # @param [Hash] params the content of SendGrid's webhook
      # @return [Array<Mail::Message>] messages
      def transform(params)
        Mail.new do
        end
      end
    end
  end
end
