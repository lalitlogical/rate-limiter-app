class FixedBucket
  attr_reader :key, :limit

  def initialize(user)
    plan = user.plan
    @key = "fixed_limit:#{plan.id}:#{user.id}"
    @limit = plan.limit
  end

  def allowed?
    now = Time.now.to_i
    puts bucket = fetch_bucket

    if bucket["expires_at"].nil? || bucket["expires_at"] <= now
      bucket = { "count" => 1, "expires_at" => now + 60 }
    else
      bucket["count"] += 1
    end

    # Check if usages limit crossed
    if bucket["count"] > limit
      return false
    end

    store_bucket(bucket)
    true
  end

  private

  def store_bucket(bucket)
    $redis.set(key, bucket.to_json)
    $redis.expireat(key, bucket["expires_at"])
  end

  def fetch_bucket
    raw = $redis.get(key)
    raw ? JSON.parse(raw) : { "count" => 0, "expires_at" => nil }
  end
end
