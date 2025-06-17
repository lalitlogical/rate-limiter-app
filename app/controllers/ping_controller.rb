class PingController < ActionController::API
  def index
    render json: { message: "pong", time: Time.now }
  end
end
