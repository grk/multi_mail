module MultiMail
  module Receiver
    # Cloudmailin's incoming email receiver.
    class Cloudmailin < MultiMail::Service
      include MultiMail::Receiver::Base

      recognizes :http_post_format

      # Initializes a Cloudmailin incoming email receiver.
      #
      # @param [Hash] options required and optional arguments
      # @option options [String] :http_post_format one of "multipart", "json",
      #   "raw" or "original"
      def initialize(options = {})
        super
        @http_post_format = options[:http_post_format]
      end

      # @param [Hash] params the content of Cloudmailin's webhook
      # @return [Boolean] whether the request originates from Cloudmailin
      # @see http://docs.cloudmailin.com/receiving_email/securing_your_email_url_target/
      def valid?(params)
        true
      end

      # @param [Hash] params the content of Cloudmailin's webhook
      # @return [Array<Mail::Message>] messages
      # @see http://docs.cloudmailin.com/http_post_formats/multipart/
      # @see http://docs.cloudmailin.com/http_post_formats/json/
      # @see http://docs.cloudmailin.com/http_post_formats/raw/
      # @see http://docs.cloudmailin.com/http_post_formats/original/
      # @todo Handle cases where the attachment store is in-use.
      def transform(params)
        case @http_post_format
        when 'multipart', 'json', '', nil
          headers = Multimap.new
          params['headers'].each do |key,value|
            if Array === value
              value.each do |v|
                headers[key] = v
              end
            else
              headers[key] = value
            end
          end

          message = Mail.new do
            headers headers

            text_part do
              body params['plain']
            end

            if params.key?('html')
              html_part do
                content_type 'text/html; charset=UTF-8'
                body params['html']
              end
            end

            if params.key?('attachments')
              params['attachments'].each do |_,attachment|
                if @http_post_format == 'json'
                  add_file(:filename => attachment['file_name'], :content => Base64.decode64(attachment['content']))
                else
                  add_file(:filename => attachment[:filename], :content => attachment[:tempfile].read)
                end
              end
            end
          end

          # Extra Cloudmailin parameters.
          message['reply_plain'] = params['reply_plain']

          # Re-use Mailgun headers.
          message['X-Mailgun-Spf'] = params['envelope']['spf']['result']

          # Discard rest of `envelope`: `from`, `to`, `recipients`,
          # `helo_domain` and `remote_ip`.
          [message]
        when 'raw'
          message = Mail.new(params['message'])
          message['X-Mailgun-Spf'] = params['envelope']['spf']['result']
          [message]
        else # @todo 'original'
          raise ArgumentError, "Can't handle Cloudmailin #{@http_post_format} HTTP POST format"
        end
      end

      # @param [Mail::Message] message a message
      # @return [Boolean] whether the message is spam
      def spam?(message)
        message['X-Mailgun-Spf'] && message['X-Mailgun-Spf'].value == 'fail'
      end
    end
  end
end