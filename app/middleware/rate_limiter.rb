# Testing with Apached Benchmark
# ab -n 5 -c 1 -H "User-Id: 1" -H "Bucket-Type: token_bucket" http://localhost:3000/ping
# ab -n 5 -c 1 -H "User-Id: 2" -H "Bucket-Type: token_bucket" http://localhost:3000/ping

# ab -n 5 -c 1 -H "User-Id: 1" -H "Bucket-Type: leaky_bucket" http://localhost:3000/ping
# ab -n 5 -c 1 -H "User-Id: 2" -H "Bucket-Type: leaky_bucket" http://localhost:3000/ping

# ab -n 100 -c 1 -H "User-Id: 2" -H "Bucket-Type: fixed_window" http://localhost:3000/ping
# ab -n 100 -c 1 -H "User-Id: 1" -H "Bucket-Type: fixed_window" http://localhost:3000/ping

class RateLimiter
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)

    # Skip monitoring endpoints
    return @app.call(env) if [ "/usage", "/usage.json", "/dashboard", "/" ].include?(request.path)

    user_id = request.get_header("HTTP_USER_ID")
    return unauthorized unless user_id

    user = User.find_by(id: user_id)
    return unauthorized unless user && user.plan

    bucket_type = request.get_header("HTTP_BUCKET_TYPE") || "fixed_window"

    puts "-" * 100
    puts "Bucket used for this request: #{bucket_type.humanize}"
    puts "-" * 100

    bucket = if bucket_type == "fixed_window"
      FixedWindow.new(user)
    elsif bucket_type == "token_bucket"
      TokenBucket.new(user)
    elsif bucket_type == "leaky_bucket"
      LeakyBucket.new(user)
    end

    unless bucket.allowed?
      puts "-" * 100
      puts "Rate limit exceeded while using #{bucket_type.humanize}."
      puts "-" * 100
      return [ 429, { "Content-Type" => "application/json" }, [ { error: "Rate limit exceeded while using #{bucket_type.humanize}." }.to_json ] ]
    end

    @app.call(env)
  end

  def unauthorized
    [ 401, { "Content-Type" => "application/json" }, [ { error: "Unauthorized" }.to_json ] ]
  end
end
