class UsageController < ActionController::API
  def index
    result = User.includes(:plan).all.map do |user|
      keys = $redis.scan_each(match: "*:#{user.id}").to_a

      usage_data = keys.map do |key|
        key_type = $redis.type(key)

        data =
          case key_type
          when "hash"
            $redis.hgetall(key)
          when "string"
            begin
              JSON.parse($redis.get(key) || "{}")
            rescue JSON::ParserError
              { raw: $redis.get(key) }
            end
          else
            { error: "Unsupported Redis type: #{key_type}" }
          end

        {
          bucket_type: key.split(":").first,
          key: key,
          data: data,
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
