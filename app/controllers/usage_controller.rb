class UsageController < ActionController::API
  def index
    result = User.all.map do |user|
      keys = $redis.scan_each(match: "*:#{user.id}").to_a

      usage_data = keys.map do |key|
        {
          bucket_type: key.split(":").first,
          key: key,
          data: JSON.parse($redis.get(key) || "{}"),
          ttl: $redis.ttl(key)
        }
      end

      {
        user_id: user.id,
        plan: user.plan.name,
        limit: user.plan.limit,
        usages: usage_data
      }
    end

    render json: result
  end
end
