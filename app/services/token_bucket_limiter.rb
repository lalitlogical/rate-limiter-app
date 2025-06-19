class TokenBucketLimiter
  LUA_SCRIPT_PATH = File.expand_path("../../../scripts/token_bucket.lua", __FILE__)
  LUA_SCRIPT = File.read(LUA_SCRIPT_PATH)

  def initialize(user)
    plan = user.plan
    @bucket_size = plan.burst_capacity
    @refill_rate = plan.token_rate || 1 # tokens/sec
    @key = "token_bucket_lua:#{plan.id}:#{user.id}"
  end

  def allowed?(consume_amount = 1)
    now_ms = (Time.now.to_f * 1000).to_i

    result = $redis.eval(
      LUA_SCRIPT,
      keys: [ @key ],
      argv: [
        @bucket_size,
        @refill_rate,
        now_ms,
        consume_amount
      ]
    )

    result == 1 || result == true
  rescue => e
    warn "Redis error (fallback deny): #{e.message}"
    false
  end
end
