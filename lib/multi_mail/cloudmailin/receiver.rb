module MultiMail
  module Receiver
    # Cloudmailin's incoming email receiver.
    class Cloudmailin < MultiMail::Service
      include MultiMail::Receiver::Base

      recognizes :http_post_format
      attr_reader :http_post_format

      # Initializes a Cloudmailin incoming email receiver.
      #
      # @param [Hash] options required and optional arguments
      # @option options [String] :http_post_format "multipart", "json" or "raw"
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
      def transform(params)
        case http_post_format
        when 'raw', '', nil
          message = self.class.condense(Mail.new(params['message']))

          # Extra Cloudmailin parameters.
          message['spf-result'] = params['envelope']['spf']['result']

          # Discard rest of `envelope`: `from`, `to`, `recipients`,
          # `helo_domain` and `remote_ip`.
          [message]
        when 'multipart', 'json'
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

          this = self
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
              if this.http_post_format == 'json'
                params['attachments'].each do |attachment|
                  add_file(:filename => attachment['file_name'], :content => Base64.decode64(attachment['content']))
                end
              else
                params['attachments'].each do |_,attachment|
                  # See the relevant comment in Mailgun's receiver.
                  if Hash === attachment
                    add_file(:filename => attachment[:filename], :content => attachment[:tempfile].read)
                  else
                    add_file(:filename => attachment.original_filename, :content => attachment.read)
                  end
                end
              end
            end
          end

          # Extra Cloudmailin parameters. The multipart format uses CRLF whereas
          # the JSON format uses LF. Normalize to LF.
          message['reply_plain'] = params['reply_plain'].gsub("\r\n", "\n")
          message['spf-result'] = params['envelope']['spf']['result']
          [message]
        else
          raise ArgumentError, "Can't handle Cloudmailin #{http_post_format} HTTP POST format"
        end
      end

      # @param [Mail::Message] message a message
      # @return [Boolean] whether the message is spam
      def spam?(message)
        message['spf-result'] && message['spf-result'].value == 'fail'
      end
    end
  end
end
