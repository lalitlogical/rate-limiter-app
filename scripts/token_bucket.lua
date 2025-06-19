local key = KEYS[1]
local max_tokens = tonumber(ARGV[1])
local refill_rate = tonumber(ARGV[2])
local now = tonumber(ARGV[3])
local tokens_to_consume = tonumber(ARGV[4])

local bucket = redis.call("HMGET", key, "tokens", "last_refill_ts")
local tokens = tonumber(bucket[1]) or max_tokens
local last_refill_ts = tonumber(bucket[2]) or now

local expires_in = 60000
local delta = math.max(0, now - last_refill_ts)
local refill = delta * refill_rate / expires_in
tokens = math.min(max_tokens, tokens + refill)

local allowed = tokens >= tokens_to_consume
if allowed then
  tokens = tokens - tokens_to_consume
end

redis.call("HMSET", key,
  "tokens", tokens,
  "last_refill_ts", now)

redis.call("PEXPIRE", key, expires_in)
return allowed
