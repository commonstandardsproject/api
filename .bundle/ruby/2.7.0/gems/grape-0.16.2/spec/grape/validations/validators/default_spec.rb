require 'spec_helper'

describe Grape::Validations::DefaultValidator do
  module ValidationsSpec
    module DefaultValidatorSpec
      class API < Grape::API
        default_format :json

        params do
          optional :id
          optional :type, default: 'default-type'
        end
        get '/' do
          { id: params[:id], type: params[:type] }
        end

        params do
          optional :type1, default: 'default-type1'
          optional :type2, default: 'default-type2'
        end
        get '/user' do
          { type1: params[:type1], type2: params[:type2] }
        end

        params do
          requires :id
          optional :type1, default: 'default-type1'
          optional :type2, default: 'default-type2'
        end

        get '/message' do
          { id: params[:id], type1: params[:type1], type2: params[:type2] }
        end

        params do
          optional :random, default: -> { Random.rand }
          optional :not_random, default: Random.rand
        end
        get '/numbers' do
          { random_number: params[:random], non_random_number: params[:non_random_number] }
        end

        params do
          optional :array, type: Array do
            requires :name
            optional :with_default, default: 'default'
          end
        end
        get '/array' do
          { array: params[:array] }
        end
      end
    end
  end

  def app
    ValidationsSpec::DefaultValidatorSpec::API
  end

  it 'set default value for optional param' do
    get('/')
    expect(last_response.status).to eq(200)
    expect(last_response.body).to eq({ id: nil, type: 'default-type' }.to_json)
  end

  it 'set default values for optional params' do
    get('/user')
    expect(last_response.status).to eq(200)
    expect(last_response.body).to eq({ type1: 'default-type1', type2: 'default-type2' }.to_json)
  end

  it 'set default values for missing params in the request' do
    get('/user?type2=value2')
    expect(last_response.status).to eq(200)
    expect(last_response.body).to eq({ type1: 'default-type1', type2: 'value2' }.to_json)
  end

  it 'set default values for optional params and allow to use required fields in the same time' do
    get('/message?id=1')
    expect(last_response.status).to eq(200)
    expect(last_response.body).to eq({ id: '1', type1: 'default-type1', type2: 'default-type2' }.to_json)
  end

  it 'sets lambda based defaults at the time of call' do
    get('/numbers')
    expect(last_response.status).to eq(200)
    before = JSON.parse(last_response.body)
    get('/numbers')
    expect(last_response.status).to eq(200)
    after = JSON.parse(last_response.body)

    expect(before['non_random_number']).to eq(after['non_random_number'])
    expect(before['random_number']).not_to eq(after['random_number'])
  end

  it 'sets default values for grouped arrays' do
    get('/array?array[][name]=name&array[][name]=name2&array[][with_default]=bar2')
    expect(last_response.status).to eq(200)
    expect(last_response.body).to eq({ array: [{ name: 'name', with_default: 'default' }, { name: 'name2', with_default: 'bar2' }] }.to_json)
  end

  context 'optional group with defaults' do
    subject do
      Class.new(Grape::API) do
        default_format :json
      end
    end

    def app
      subject
    end

    context 'optional array without default value includes optional param with default value' do
      before do
        subject.params do
          optional :optional_array, type: Array do
            optional :foo_in_optional_array, default: 'bar'
          end
        end
        subject.post '/optional_array' do
          { optional_array: params[:optional_array] }
        end
      end

      it 'returns nil for optional array if param is not provided' do
        post '/optional_array'
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq({ optional_array: nil }.to_json)
      end
    end

    context 'optional array with default value includes optional param with default value' do
      before do
        subject.params do
          optional :optional_array_with_default, type: Array, default: [] do
            optional :foo_in_optional_array, default: 'bar'
          end
        end
        subject.post '/optional_array_with_default' do
          { optional_array_with_default: params[:optional_array_with_default] }
        end
      end

      it 'sets default value for optional array if param is not provided' do
        post '/optional_array_with_default'
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq({ optional_array_with_default: [] }.to_json)
      end
    end

    context 'optional hash without default value includes optional param with default value' do
      before do
        subject.params do
          optional :optional_hash_without_default, type: Hash do
            optional :foo_in_optional_hash, default: 'bar'
          end
        end
        subject.post '/optional_hash_without_default' do
          { optional_hash_without_default: params[:optional_hash_without_default] }
        end
      end

      it 'returns nil for optional hash if param is not provided' do
        post '/optional_hash_without_default'
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq({ optional_hash_without_default: nil }.to_json)
      end

      it 'does not fail even if invalid params is passed to default validator' do
        expect { post '/optional_hash_without_default', optional_hash_without_default: '5678' }.not_to raise_error
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq({ error: 'optional_hash_without_default is invalid' }.to_json)
      end
    end

    context 'optional hash with default value includes optional param with default value' do
      before do
        subject.params do
          optional :optional_hash_with_default, type: Hash, default: {} do
            optional :foo_in_optional_hash, default: 'bar'
          end
        end
        subject.post '/optional_hash_with_default_empty_hash' do
          { optional_hash_with_default: params[:optional_hash_with_default] }
        end

        subject.params do
          optional :optional_hash_with_default, type: Hash, default: { foo_in_optional_hash: 'parent_default' } do
            optional :some_param
            optional :foo_in_optional_hash, default: 'own_default'
          end
        end
        subject.post '/optional_hash_with_default_inner_params' do
          { foo_in_optional_hash: params[:optional_hash_with_default][:foo_in_optional_hash] }
        end
      end

      it 'sets default value for optional hash if param is not provided' do
        post '/optional_hash_with_default_empty_hash'
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq({ optional_hash_with_default: {} }.to_json)
      end

      it 'sets default value from parent defaults for inner param if parent param is not provided' do
        post '/optional_hash_with_default_inner_params'
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq({ foo_in_optional_hash: 'parent_default' }.to_json)
      end

      it 'sets own default value for inner param if parent param is provided' do
        post '/optional_hash_with_default_inner_params', optional_hash_with_default: { some_param: 'param' }
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq({ foo_in_optional_hash: 'own_default' }.to_json)
      end
    end
  end
end
