# app/controllers/usage_controller.rb
class UsageController < ApplicationController
  def index
    users = User.all

    result = users.map do |user|
      rate_limiter_service = RateLimiterService.new(user)
      key = rate_limiter_service.key
      usage = rate_limiter_service.current_usage
      ttl = $redis.ttl(key)

      {
        user_id: user.id,
        plan: user.plan.name,
        usage: usage["count"],
        limit: user.plan.limit,
        reset_in_seconds: ttl
      }
    end

    render json: result
  end
end
