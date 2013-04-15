module MultiMail
  # Endpoint for initializing different incoming email receivers.
  #
  # @see http://rdoc.info/gems/fog/Fog/Storage
  module Receiver
    # Initializes an incoming email receiver.
    #
    # @example
    #   require 'multi_mail'
    #   service = MultiMail::Receiver.new({
    #     :provider => 'mailgun',
    #     :mailgun_api_key => 'key-xxxxxxxxxxxxxxxxxxxxxxx-x-xxxxxx',
    #   })
    #
    # @param [Hash] attributes required arguments
    # @option opts [String,Symbol] :provider a provider
    # @return [MultiMail::Service] an incoming email receiver
    # @raise [ArgumentError] if the provider does not exist
    # @see Fog::Storage::new
    def self.new(attributes)
      attributes = attributes.dup # prevent delete from having side effects
      case provider = attributes.delete(:provider).to_s.downcase.to_sym
      when :cloudmailin
        require 'multi_mail/cloudmailin/receiver'
        MultiMail::Receiver::Cloudmailin.new(attributes)
      when :mailgun
        require 'multi_mail/mailgun/receiver'
        MultiMail::Receiver::Mailgun.new(attributes)
      when :mandrill
        require 'multi_mail/mandrill/receiver'
        MultiMail::Receiver::Mandrill.new(attributes)
      when :postmark
        require 'multi_mail/postmark/receiver'
        MultiMail::Receiver::Postmark.new(attributes)
      when :sendgrid
        require 'multi_mail/sendgrid/receiver'
        MultiMail::Receiver::SendGrid.new(attributes)
      when :simple
        require 'multi_mail/simple/receiver'
        MultiMail::Receiver::Simple.new(attributes)
      when :mock
        # for testing
        MultiMail::Receiver::Mock.new(attributes)
      else
        raise ArgumentError.new("#{provider} is not a recognized provider")
      end
    end
  end
end
