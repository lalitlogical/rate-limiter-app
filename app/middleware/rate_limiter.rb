# app/middleware/rate_limiter.rb
class RateLimiter
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)

    # Skip monitoring endpoints
    return @app.call(env) if [ "/usage", "/dashboard" ].include?(request.path)

    user_id = request.get_header("HTTP_USER_ID")
    return unauthorized unless user_id

    user = User.find_by(id: user_id)
    return unauthorized unless user

    # if request not allowed
    unless RateLimiterService.new(user).allowed?
      return [ 429, { "Content-Type" => "application/json" }, [ { error: "Rate limit exceeded" }.to_json ] ]
    end

    @app.call(env)
  end

  def unauthorized
    [ 401, { "Content-Type" => "application/json" }, [ { error: "Unauthorized" }.to_json ] ]
  end
end
