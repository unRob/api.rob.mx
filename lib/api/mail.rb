module API
  class Mail

    attr_accessor :text, :html, :from_name, :from_email, :to, :bcc, :cc, :subject

    @@__contacts = {}
    @@__sender = nil
    @@__recipient = nil

    class << self
      def configure client, contacts
        @@__contacts = contacts
        @@__client = client

        contacts.each do |name, data|
          if data[:default_sender]
            @@__sender = name
          elsif data[:default_recipient]
            @@__recipient = name
          end
        end
      end

      def client
        @@__client
      end

      def sender
        @@__contacts[@@__sender].tap {|c|
          c.delete :default_sender if c.is_a? Hash
        }
      end

      def recipient
        @@__contacts[@@__recipient].tap {|c|
          c.delete :default_recipient if c.is_a? Hash
        }
      end
    end

    @text = nil
    @html = nil
    @cc = []
    @bcc = []
    @to = []

    def initialize title, as_text, markup=nil
      @sent = false
      self.text = as_text
      self.subject = title
      self.html = markup if markup
      @to = []
      @cc = []
      @bcc = []
    end


    def html= markup
      if markup == :markdown
        markup = Maruku.new(text).to_html
      end
      @html = markup
    end


    def to_h
      data = {
        subject: subject,
        text: text,
        html: html,
        to: @recipients,
        from_email: from_email
      }
      data[:from_name] = from_name if from_name

      data
    end


    def send_async opts={}
      send opts.merge(async: true)
    end


    def send async: false, at: :now
      raise "Message already sent" if @sent
      _to = to.empty? ? [Mail.recipient] : as_address(to)

      @recipients = (
        _to +
        as_address(cc, :cc) +
        as_address(bcc, :bcc)
      ).compact

      if Mail.sender
        self.from_email ||= Mail.sender[:email]
        self.from_name  ||= Mail.sender[:name]
      end

      raise "No sender set (use #from_email to set)" if from_email.nil?

      at = case at
        when :now then nil
        when String then at
        when DateTime, Time then at.sprintf("%F %T")
      end

      Mail.client.messages.send(to_h, async, nil, at)
      @sent = true
      self
    end


    private
    def as_address addresses, type=nil
      return [] if addresses.nil?
      addresses = [addresses] unless addresses.is_a? Array
      addresses.map { |addr|
        fqa = case addr
          when Hash then addr
          when String then {email: addr}
          when Symbol then {
            email: @@__defaults[addr][:email],
            name: @@__defaults[addr][:name]}
        end
        fqa[:type] = type if type
      }
    end

  end
end