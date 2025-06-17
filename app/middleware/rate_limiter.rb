# app/middleware/rate_limiter.rb
class RateLimiter
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)
    user_id = request.get_header("HTTP_USER_ID")
    plan = request.get_header("HTTP_PLAN") || "free"

    key = "rate_limit:#{plan}:#{user_id}"
    limit = plan == "paid" ? 100 : 10  # requests per minute

    current = $redis.get(key).to_i
    if current >= limit
      return [ 429, { "Content-Type" => "application/json" }, [ { error: "Rate limit exceeded" }.to_json ] ]
    else
      $redis.multi do
        $redis.incr(key)
        $redis.expire(key, 60)
      end
    end

    @app.call(env)
  end
end
