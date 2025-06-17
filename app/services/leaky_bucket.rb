class LeakyBucket
  attr_reader :key, :leak_rate, :capacity

  def initialize(user)
    plan = user.plan
    @key = "leaky_bucket:#{plan.id}:#{user.id}"
    @leak_rate = plan.leak_rate || 1.0     # requests per second
    @capacity = plan.bucket_capacity || 10 # max queued requests
  end

  def allowed?
    now = Time.now.to_f
    puts bucket = fetch_bucket

    # Calculate how many leaked since last
    elapsed = now - bucket["last_leak_time"]
    leaked = (elapsed * leak_rate).floor

    # Reduce queued count by leaked amount
    bucket["queued_requests"] = [ 0, bucket["queued_requests"] - leaked ].max
    bucket["last_leak_time"] = now if leaked > 0

    if bucket["queued_requests"] < capacity
      bucket["queued_requests"] += 1
      store_bucket(bucket)
      true
    else
      store_bucket(bucket)
      false
    end
  end

  private

  def fetch_bucket
    raw = $redis.get(key)
    if raw
      JSON.parse(raw)
    else
      { "queued_requests" => 0, "last_leak_time" => Time.now.to_f }
    end
  end

  def store_bucket(bucket)
    $redis.set(key, bucket.to_json, ex: 3600)
  end
end
