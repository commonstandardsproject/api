require 'spec_helper'

describe Grape::Middleware::Formatter do
  subject { Grape::Middleware::Formatter.new(app) }
  before { allow(subject).to receive(:dup).and_return(subject) }

  let(:app) { ->(_env) { [200, {}, [@body || { 'foo' => 'bar' }]] } }

  context 'serialization' do
    it 'looks at the bodies for possibly serializable data' do
      @body = { 'abc' => 'def' }
      _, _, bodies = *subject.call('PATH_INFO' => '/somewhere', 'HTTP_ACCEPT' => 'application/json')
      bodies.each { |b| expect(b).to eq(MultiJson.dump(@body)) }
    end

    it 'calls #to_json since default format is json' do
      @body = ['foo']
      @body.instance_eval do
        def to_json
          "\"bar\""
        end
      end

      subject.call('PATH_INFO' => '/somewhere', 'HTTP_ACCEPT' => 'application/json').to_a.last.each { |b| expect(b).to eq('"bar"') }
    end

    it 'calls #to_json if the content type is jsonapi' do
      @body = { 'foos' => [{ 'bar' => 'baz' }] }
      @body.instance_eval do
        def to_json
          "{\"foos\":[{\"bar\":\"baz\"}] }"
        end
      end

      subject.call('PATH_INFO' => '/somewhere', 'HTTP_ACCEPT' => 'application/vnd.api+json').to_a.last.each { |b| expect(b).to eq('{"foos":[{"bar":"baz"}] }') }
    end

    it 'calls #to_xml if the content type is xml' do
      @body = 'string'
      @body.instance_eval do
        def to_xml
          '<bar/>'
        end
      end

      subject.call('PATH_INFO' => '/somewhere.xml', 'HTTP_ACCEPT' => 'application/json').to_a.last.each { |b| expect(b).to eq('<bar/>') }
    end
  end

  context 'error handling' do
    let(:formatter) { double(:formatter) }
    before do
      allow(Grape::Formatter).to receive(:formatter_for) { formatter }
    end

    it 'rescues formatter-specific exceptions' do
      allow(formatter).to receive(:call) { fail Grape::Exceptions::InvalidFormatter.new(String, 'xml') }

      expect do
        catch(:error) { subject.call('PATH_INFO' => '/somewhere.xml', 'HTTP_ACCEPT' => 'application/json') }
      end.to_not raise_error
    end

    it 'does not rescue other exceptions' do
      allow(formatter).to receive(:call) { fail StandardError }

      expect do
        catch(:error) { subject.call('PATH_INFO' => '/somewhere.xml', 'HTTP_ACCEPT' => 'application/json') }
      end.to raise_error(StandardError)
    end
  end

  context 'detection' do
    it 'uses the xml extension if one is provided' do
      subject.call('PATH_INFO' => '/info.xml')
      expect(subject.env['api.format']).to eq(:xml)
    end

    it 'uses the json extension if one is provided' do
      subject.call('PATH_INFO' => '/info.json')
      expect(subject.env['api.format']).to eq(:json)
    end

    it 'uses the format parameter if one is provided' do
      subject.call('PATH_INFO' => '/info', 'QUERY_STRING' => 'format=json')
      expect(subject.env['api.format']).to eq(:json)
      subject.call('PATH_INFO' => '/info', 'QUERY_STRING' => 'format=xml')
      expect(subject.env['api.format']).to eq(:xml)
    end

    it 'uses the default format if none is provided' do
      subject.call('PATH_INFO' => '/info')
      expect(subject.env['api.format']).to eq(:txt)
    end

    it 'uses the requested format if provided in headers' do
      subject.call('PATH_INFO' => '/info', 'HTTP_ACCEPT' => 'application/json')
      expect(subject.env['api.format']).to eq(:json)
    end

    it 'uses the file extension format if provided before headers' do
      subject.call('PATH_INFO' => '/info.txt', 'HTTP_ACCEPT' => 'application/json')
      expect(subject.env['api.format']).to eq(:txt)
    end
  end

  context 'accept header detection' do
    it 'detects from the Accept header' do
      subject.call('PATH_INFO' => '/info', 'HTTP_ACCEPT' => 'application/xml')
      expect(subject.env['api.format']).to eq(:xml)
    end

    it 'uses quality rankings to determine formats' do
      subject.call('PATH_INFO' => '/info', 'HTTP_ACCEPT' => 'application/json; q=0.3,application/xml; q=1.0')
      expect(subject.env['api.format']).to eq(:xml)
      subject.call('PATH_INFO' => '/info', 'HTTP_ACCEPT' => 'application/json; q=1.0,application/xml; q=0.3')
      expect(subject.env['api.format']).to eq(:json)
    end

    it 'handles quality rankings mixed with nothing' do
      subject.call('PATH_INFO' => '/info', 'HTTP_ACCEPT' => 'application/json,application/xml; q=1.0')
      expect(subject.env['api.format']).to eq(:xml)
    end

    it 'parses headers with other attributes' do
      subject.call('PATH_INFO' => '/info', 'HTTP_ACCEPT' => 'application/json; abc=2.3; q=1.0,application/xml; q=0.7')
      expect(subject.env['api.format']).to eq(:json)
    end

    it 'parses headers with vendor and api version' do
      subject.call('PATH_INFO' => '/info', 'HTTP_ACCEPT' => 'application/vnd.test-v1+xml')
      expect(subject.env['api.format']).to eq(:xml)
    end

    context 'with custom vendored content types' do
      before do
        subject.options[:content_types] = {}
        subject.options[:content_types][:custom] = 'application/vnd.test+json'
      end

      it 'it uses the custom type' do
        subject.call('PATH_INFO' => '/info', 'HTTP_ACCEPT' => 'application/vnd.test+json')
        expect(subject.env['api.format']).to eq(:custom)
      end
    end

    it 'parses headers with symbols as hash keys' do
      subject.call('PATH_INFO' => '/info', 'http_accept' => 'application/xml', system_time: '091293')
      expect(subject.env[:system_time]).to eq('091293')
    end
  end

  context 'content-type' do
    it 'is set for json' do
      _, headers, = subject.call('PATH_INFO' => '/info.json')
      expect(headers['Content-type']).to eq('application/json')
    end
    it 'is set for xml' do
      _, headers, = subject.call('PATH_INFO' => '/info.xml')
      expect(headers['Content-type']).to eq('application/xml')
    end
    it 'is set for txt' do
      _, headers, = subject.call('PATH_INFO' => '/info.txt')
      expect(headers['Content-type']).to eq('text/plain')
    end
    it 'is set for custom' do
      subject.options[:content_types] = {}
      subject.options[:content_types][:custom] = 'application/x-custom'
      _, headers, = subject.call('PATH_INFO' => '/info.custom')
      expect(headers['Content-type']).to eq('application/x-custom')
    end
    it 'is set for vendored with registered type' do
      subject.options[:content_types] = {}
      subject.options[:content_types][:custom] = 'application/vnd.test+json'
      _, headers, = subject.call('PATH_INFO' => '/info', 'HTTP_ACCEPT' => 'application/vnd.test+json')
      expect(headers['Content-type']).to eq('application/vnd.test+json')
    end
    it 'is set to closest generic for custom vendored/versioned without registered type' do
      _, headers, = subject.call('PATH_INFO' => '/info', 'HTTP_ACCEPT' => 'application/vnd.test+json')
      expect(headers['Content-type']).to eq('application/json')
    end
  end

  context 'format' do
    it 'uses custom formatter' do
      subject.options[:content_types] = {}
      subject.options[:content_types][:custom] = "don't care"
      subject.options[:formatters][:custom] = ->(_obj, _env) { 'CUSTOM FORMAT' }
      _, _, body = subject.call('PATH_INFO' => '/info.custom')
      expect(body.body).to eq(['CUSTOM FORMAT'])
    end
    it 'uses default json formatter' do
      @body = ['blah']
      _, _, body = subject.call('PATH_INFO' => '/info.json')
      expect(body.body).to eq(['["blah"]'])
    end
    it 'uses custom json formatter' do
      subject.options[:formatters][:json] = ->(_obj, _env) { 'CUSTOM JSON FORMAT' }
      _, _, body = subject.call('PATH_INFO' => '/info.json')
      expect(body.body).to eq(['CUSTOM JSON FORMAT'])
    end
  end

  context 'no content responses' do
    let(:no_content_response) { ->(status) { [status, {}, ['']] } }

    Rack::Utils::STATUS_WITH_NO_ENTITY_BODY.each do |status|
      it "does not modify a #{status} response" do
        expected_response = no_content_response[status]
        allow(app).to receive(:call).and_return(expected_response)
        expect(subject.call({})).to eq(expected_response)
      end
    end
  end

  context 'input' do
    %w(POST PATCH PUT DELETE).each do |method|
      ['application/json', 'application/json; charset=utf-8'].each do |content_type|
        context content_type do
          it "parses the body from #{method} and copies values into rack.request.form_hash" do
            io = StringIO.new('{"is_boolean":true,"string":"thing"}')
            subject.call(
              'PATH_INFO' => '/info',
              'REQUEST_METHOD' => method,
              'CONTENT_TYPE' => content_type,
              'rack.input' => io,
              'CONTENT_LENGTH' => io.length
            )
            expect(subject.env['rack.request.form_hash']['is_boolean']).to be true
            expect(subject.env['rack.request.form_hash']['string']).to eq('thing')
          end
        end
      end
      it "parses the chunked body from #{method} and copies values into rack.request.from_hash" do
        io = StringIO.new('{"is_boolean":true,"string":"thing"}')
        subject.call(
          'PATH_INFO' => '/infol',
          'REQUEST_METHOD' => method,
          'CONTENT_TYPE' => 'application/json',
          'rack.input' => io,
          'HTTP_TRANSFER_ENCODING' => 'chunked'
        )
        expect(subject.env['rack.request.form_hash']['is_boolean']).to be true
        expect(subject.env['rack.request.form_hash']['string']).to eq('thing')
      end
      it 'rewinds IO' do
        io = StringIO.new('{"is_boolean":true,"string":"thing"}')
        io.read
        subject.call(
          'PATH_INFO' => '/infol',
          'REQUEST_METHOD' => method,
          'CONTENT_TYPE' => 'application/json',
          'rack.input' => io,
          'HTTP_TRANSFER_ENCODING' => 'chunked'
        )
        expect(subject.env['rack.request.form_hash']['is_boolean']).to be true
        expect(subject.env['rack.request.form_hash']['string']).to eq('thing')
      end
      it "parses the body from an xml #{method} and copies values into rack.request.from_hash" do
        io = StringIO.new('<thing><name>Test</name></thing>')
        subject.call(
          'PATH_INFO' => '/info.xml',
          'REQUEST_METHOD' => method,
          'CONTENT_TYPE' => 'application/xml',
          'rack.input' => io,
          'CONTENT_LENGTH' => io.length
        )
        expect(subject.env['rack.request.form_hash']['thing']['name']).to eq('Test')
      end
      [Rack::Request::FORM_DATA_MEDIA_TYPES, Rack::Request::PARSEABLE_DATA_MEDIA_TYPES].flatten.each do |content_type|
        it "ignores #{content_type}" do
          io = StringIO.new('name=Other+Test+Thing')
          subject.call(
            'PATH_INFO' => '/info',
            'REQUEST_METHOD' => method,
            'CONTENT_TYPE' => content_type,
            'rack.input' => io,
            'CONTENT_LENGTH' => io.length
          )
          expect(subject.env['rack.request.form_hash']).to be_nil
        end
      end
    end
  end

  context 'send file' do
    let(:app) { ->(_env) { [200, {}, @body] } }

    it 'returns Grape::Uril::SendFileReponse' do
      @body = Grape::ServeFile::FileResponse.new('file')
      env = { 'PATH_INFO' => '/somewhere', 'HTTP_ACCEPT' => 'application/json' }
      expect(subject.call(env)).to be_a(Grape::ServeFile::SendfileResponse)
    end
  end

  context 'inheritable formatters' do
    class InvalidFormatter
      def self.call(_, _)
        { message: 'invalid' }.to_json
      end
    end
    let(:app) { ->(_env) { [200, {}, ['']] } }
    before do
      Grape::Formatter.register :invalid, InvalidFormatter
      Grape::ContentTypes::CONTENT_TYPES[:invalid] = 'application/x-invalid'
    end

    it 'returns response by invalid formatter' do
      env = { 'PATH_INFO' => '/hello.invalid', 'HTTP_ACCEPT' => 'application/x-invalid' }
      _, _, bodies = *subject.call(env)
      expect(bodies.body.first).to eq({ message: 'invalid' }.to_json)
    end
  end
end
