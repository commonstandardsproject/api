module ContentTypeHelpers
  %w(put patch post delete).each do |method|
    define_method :"#{method}_with_json" do |uri, params = {}, env = {}, &block|
      params = params.to_json
      env['CONTENT_TYPE'] ||= 'application/json'
      send(method, uri, params, env, &block)
    end
  end
end

include(ContentTypeHelpers)
