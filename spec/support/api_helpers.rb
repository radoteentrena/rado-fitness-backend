module ApiHelpers
  def auth_headers(user)
    { 'Authorization' => "Token #{user.auth_token}" }
  end

  def json
    JSON.parse(response.body)
  end
end
