module ApiHelpers
  def auth_headers(user)
    { 'Authorization' => "Token #{user.auth_token}", 'Accept' => 'application/json' }
  end

  def json
    JSON.parse(response.body)
  end
end
