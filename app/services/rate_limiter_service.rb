class RateLimiterService
  def initialize(user)
    @user_id = user.id
    @plan = user.plan
  end

  def plan
    @plan
  end

  def user_id
    @user_id
  end

  def key
    "rate_limit:#{plan.id}:#{user_id}"
  end

  def limit
    @limit ||= plan.limit
  end

  def allowed?
    usage = current_usage

    now = Time.now.to_i
    if usage["expires_at"].nil? || usage["expires_at"] <= now
      usage = { "count" => 1, "expires_at" => now + 60 }
    else
      usage["count"] += 1
    end

    # Check if usages limit crossed
    if usage["count"] > limit
      return false
    else
      store_usage(usage)
    end

    true
  end

  def store_usage(usage)
    $redis.set(key, usage.to_json)
    $redis.expireat(key, usage["expires_at"])
  end

  def current_usage
    data = $redis.get(key)
    data ? JSON.parse(data) : { "count" => 0, "expires_at" => nil }
  end
end
