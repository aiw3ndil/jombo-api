module AuthenticationHelper
  def auth_headers(user)
    token = JwtService.encode(user_id: user.id, email: user.email)
    { 'Cookie' => "jwt=#{token}" }
  end

  def authenticated_request(method, path, user, params: {})
    headers = auth_headers(user)
    send(method, path, params: params, headers: headers)
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelper, type: :request
end
