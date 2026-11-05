require 'rails_helper'

RSpec.describe SmsService do
  let(:http) { instance_double(Net::HTTP) }
  let(:sent) { [] }

  around do |example|
    keys = %w[TEXTBEE_API_KEY TEXTBEE_DEVICE_ID TEXTBEE_API_URL]
    saved = keys.to_h { |k| [k, ENV[k]] }
    example.run
  ensure
    saved.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
  end

  def stub_http(response)
    allow(Net::HTTP).to receive(:start) do |host, _port, **_opts, &block|
      allow(http).to receive(:request) { |req| sent << [host, req]; response }
      block.call(http)
    end
  end

  context 'without TEXTBEE_API_KEY' do
    before { ENV.delete('TEXTBEE_API_KEY') }

    it 'logs the message outside production' do
      described_class.deliveries.clear
      described_class.deliver(to: '+358401234567', body: 'Code 123456')
      expect(described_class.deliveries.last).to eq(to: '+358401234567', body: 'Code 123456')
      expect(described_class.enabled?).to be(true)
    end

    it 'is disabled in production' do
      allow(Rails.env).to receive(:production?).and_return(true)
      expect(described_class.enabled?).to be(false)
      expect { described_class.deliver(to: '+358401234567', body: 'x') }.to raise_error(SmsService::DeliveryError)
    end
  end

  context 'with TEXTBEE_API_KEY' do
    before do
      ENV['TEXTBEE_API_KEY'] = 'key-123'
      ENV['TEXTBEE_DEVICE_ID'] = 'device-1'
    end

    it 'sends the SMS through the textbee API' do
      stub_http(Net::HTTPCreated.new('1.1', '201', 'Created'))
      described_class.deliver(to: '+358401234567', body: 'Code 123456')

      host, request = sent.last
      expect(host).to eq('api.textbee.dev')
      expect(request.path).to eq('/api/v1/gateway/send-sms')
      expect(request['x-api-key']).to eq('key-123')
      expect(JSON.parse(request.body)).to eq('recipients' => ['+358401234567'], 'message' => 'Code 123456',
                                             'deviceId' => 'device-1')
    end

    it 'raises DeliveryError when textbee rejects the request' do
      response = Net::HTTPUnauthorized.new('1.1', '401', 'Unauthorized')
      allow(response).to receive(:body).and_return('{"error":"invalid api key"}')
      stub_http(response)
      expect { described_class.deliver(to: '+358401234567', body: 'x') }
        .to raise_error(SmsService::DeliveryError, /textbee 401/)
    end

    it 'raises DeliveryError when the gateway is unreachable' do
      allow(Net::HTTP).to receive(:start).and_raise(Net::OpenTimeout)
      expect { described_class.deliver(to: '+358401234567', body: 'x') }
        .to raise_error(SmsService::DeliveryError, /unreachable/)
    end
  end
end
