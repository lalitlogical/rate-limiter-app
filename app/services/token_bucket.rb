# app/services/token_bucket.rb
class TokenBucket
  def initialize(user:, rate:, burst_capacity:)
    @rate = rate                # tokens per second
    @burst = burst_capacity     # max bucket size
    @key = "rate_limit:#{user.plan.id}:#{user.id}"
  end

  def allowed?
    now = Time.now.to_f

    # get stored state
    state = $redis.get(@key)
    bucket = state ? JSON.parse(state) : { "tokens" => @burst, "last" => now }

    elapsed = now - bucket["last"]
    new_tokens = (elapsed * @rate).floor
    bucket["tokens"] = [ @burst, bucket["tokens"] + new_tokens ].min
    bucket["last"] = now

    if bucket["tokens"] > 0
      bucket["tokens"] -= 1
      $redis.set(@key, bucket.to_json)
      true
    else
      $redis.set(@key, bucket.to_json)
      false
    end
  end
end
