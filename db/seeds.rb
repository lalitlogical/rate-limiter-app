# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

free_plan = Plan.find_or_create_by(
  name: "free",
  limit: 10,
  burst_capacity: 10,
  token_rate: 1,
  bucket_capacity: 10,
  leak_rate: 1
)

paid_plan = Plan.find_or_create_by(
  name: "paid",
  limit: 100,
  burst_capacity: 100,
  token_rate: 5,
  bucket_capacity: 100,
  leak_rate: 5
)

User.find_or_create_by(name: "FreeUser", plan: free_plan)
User.find_or_create_by(name: "PaidUser", plan: paid_plan)
