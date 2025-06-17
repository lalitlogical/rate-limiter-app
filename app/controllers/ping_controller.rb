class PingController < ApplicationController
  def index
    render json: { message: "pong", time: Time.now }
  end
end
