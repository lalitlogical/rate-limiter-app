# app/services/token_bucket.rb
class TokenBucket
  attr_reader :key, :rate, :burst

  def initialize(user)
    plan = user.plan
    @key = "token_bucket:#{plan.id}:#{user.id}"
    @rate = plan.token_rate || 1         # tokens/sec
    @burst = plan.burst_capacity || 10   # max burst
  end

  def allowed?
    now = Time.now.to_f
    puts bucket = fetch_bucket(now)

    elapsed = now - bucket["last"]
    new_tokens = (elapsed * rate).floor
    bucket["tokens"] = [ burst, bucket["tokens"] + new_tokens ].min
    bucket["last"] = now

    if bucket["tokens"] > 0
      bucket["tokens"] -= 1
      store_bucket(bucket)
      true
    else
      store_bucket(bucket)
      false
    end
  end

  private

  def store_bucket(bucket)
    $redis.set(key, bucket.to_json, ex: 3600)
  end

  def fetch_bucket(now)
    raw = $redis.get(key)
    raw ? JSON.parse(raw) : { "tokens" => burst, "last" => now }
  end
end
