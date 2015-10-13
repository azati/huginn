module Agents
  class BeeperAgent < Agent

    cannot_be_scheduled!
    cannot_create_events!

    API_BASE = 'https://api.beeper.io/api'.freeze

    TYPE_TO_ATTRIBUTES = {
      'message'  => %w(text),
      'image'    => %w(text image),
      'event'    => %w(text start_time end_time),
      'location' => %w(text latitude longitude),
      'task'     => %w(text)
    }.freeze

    MESSAGE_TYPES = TYPE_TO_ATTRIBUTES.keys

    TYPE_REQUIRED_ATTRIBUTES = {
      'message'  => %w(text),
      'image'    => %w(image),
      'event'    => %w(text start_time),
      'location' => %w(latitude longitude),
      'task'     => %w(text)
    }.freeze

    def default_options
      {
        'type'      => 'message',
        'app_id'    => '<BEEPER_APPLICATION_ID>',
        'api_key'   => '<BEEPER_REST_API_KEY>',
        'sender_id' => '',
        'phone'     => '',
        'group_id'  => '',
        'text'      => '{{title}}'
      }
    end

    def validate_options
      %w(app_id api_key sender_id type).each do |attr|
        errors.add(:base, "you need to specify a #{attr}") if options[attr].blank?
      end

      if !options['type'].in?(MESSAGE_TYPES)
        errors.add(:base, 'you need to specify a valid message type')
      else
        required_attributes = TYPE_REQUIRED_ATTRIBUTES[options['type']]
        if required_attributes.any? {|attr| options[attr].blank? }
          errors.add(:base, "you need to specify a #{required_attributes.join(', ')}")
        end
      end


      unless options['group_id'].blank? ^ options['phone'].blank?
        errors.add(:base, 'you need to specify a phone or group_id')
      end
    end

    def working?
      received_event_without_error?
    end

    def receive(incoming_events)
      incoming_events.each do |event|
        log(send_message(event))
      end
    end

    def send_message(event)
      mo = interpolated(event)
      begin
        HTTParty.post(endpoint_for(mo['type']), body: payload_for(mo),
          headers: headers)
      rescue HTTParty::Error  => e
        error(e.message)
      end
    end

    private

    def headers
      {
        'X-Beeper-Application-Id' => options['app_id'],
        'X-Beeper-REST-API-Key'   => options['api_key'],
        'Content-Type' => 'application/json'
      }
    end

    def payload_for(mo)
      payload = mo.slice(*TYPE_TO_ATTRIBUTES[mo['type']], 'sender_id', 'phone',
        'group_id').to_json
      log(payload)
      payload
    end

    def endpoint_for(type)
      "#{API_BASE}/#{type}s.json"
    end
  end
end