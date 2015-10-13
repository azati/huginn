require 'spec_helper'


describe Agents::BeeperAgent do
  let(:base_params) {
    {
      'type'      => 'message',
      'app_id'    => 'some-app-id',
      'api_key'   => 'some-api-key',
      'sender_id' => 'sender-id',
      'phone'     => '+111111111111',
      'text'      => 'Some text'
    }
  }

  subject {
    agent = described_class.new(name: 'beeper-agent', options: base_params)
    agent.user = users(:jane)
    agent.save and return agent
  }

  context 'validation' do
    it 'should be valid' do
      expect(subject).to be_valid
    end

    [:type, :app_id, :api_key, :sender_id].each do |attr|
      it "should be invalid without #{attr}" do
        subject.options[attr] = nil
        expect(subject).not_to be_valid
      end
    end

    context '#message' do
      it 'should require text' do
        subject.options[:text] = nil
        expect(subject).not_to be_valid
      end
    end

    context '#image' do
      before(:each) do
        subject.options[:type] = 'image'
      end

      it 'should be invalid without image' do
        expect(subject).not_to be_valid
      end

      it 'should be valid with image' do
        subject.options[:image] = 'some-url'
        expect(subject).to be_valid
      end
    end

    context '#event' do
      before(:each) do
        subject.options[:type] = 'event'
      end

      it 'should be invalid without start_time' do
        expect(subject).not_to be_valid
      end

      it 'should be valid with start_time' do
        subject.options[:start_time] = Time.now
        expect(subject).to be_valid
      end
    end

    context '#location' do
      before(:each) do
        subject.options[:type] = 'location'
      end

      it 'should be invalid without latitude and longitude' do
        expect(subject).not_to be_valid
      end

      it 'should be valid with latitude and longitude' do
        subject.options[:latitude] = 15.0
        subject.options[:longitude] = 16.0
        expect(subject).to be_valid
      end
    end

    context '#task' do
      before(:each) do
        subject.options[:type] = 'task'
      end

      it 'should be valid with text' do
        expect(subject).to be_valid
      end
    end
  end

  context 'payload_for' do
    it 'should remove unwanted attributes' do
      result = subject.send(:payload_for, {'type' => 'message', 'text' => 'text',
        'sender_id' => 'sender', 'phone' => '+1', 'random_attribute' => 'unwanted'})
      expect(result).to eq('{"text":"text","sender_id":"sender","phone":"+1"}')
    end
  end

  context 'headers' do
    it 'should set X-Beeper-Application-Id header with app_id' do
      expect(subject.send(:headers)['X-Beeper-Application-Id']).to eq(base_params['app_id'])
    end

    it 'should set X-Beeper-REST-API-Key header with api_key' do
      expect(subject.send(:headers)['X-Beeper-REST-API-Key']).to eq(base_params['api_key'])
    end

    it 'should set Content-Type' do
      expect(subject.send(:headers)['Content-Type']).to eq('application/json')
    end
  end

  context 'endpoint_for' do
    it 'should return valid URL for message' do
      expect(subject.send(:endpoint_for, 'message')).to eq('https://api.beeper.io/api/messages.json')
    end

    it 'should return valid URL for image' do
      expect(subject.send(:endpoint_for, 'image')).to eq('https://api.beeper.io/api/images.json')
    end

    it 'should return valid URL for event' do
      expect(subject.send(:endpoint_for, 'event')).to eq('https://api.beeper.io/api/events.json')
    end

    it 'should return valid URL for location' do
      expect(subject.send(:endpoint_for, 'location')).to eq('https://api.beeper.io/api/locations.json')
    end
    it 'should return valid URL for task' do
      expect(subject.send(:endpoint_for, 'task')).to eq('https://api.beeper.io/api/tasks.json')
    end
  end
end
