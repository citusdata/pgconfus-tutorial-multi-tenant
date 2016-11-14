#!/usr/bin/env ruby
# rubocop:disable all

require 'digest/sha1'
require 'securerandom'
require 'faker'
require 'csv'
require 'json'

user_count = 1 # 100
stores_per_user = 1..2
products_per_store = 10..50
orders_per_store = 1000..10000
line_items_per_order = 1..5

categories = ['Art', 'Electronics', 'Entertainment', 'Fashion', 'Home & Garden', 'Sporting Goods', 'Other']
states = ['open', 'processing', 'fulfilled']

def fake_address
  [
    Faker::Name.name,
    Faker::Address.street_address, Faker::Address.secondary_address,
    [Faker::Address.city_prefix + Faker::Address.city_suffix + ',', Faker::Address.state_abbr, Faker::Address.zip_code].join(' '),
    'United States'
  ].join("\n")
end

user_count.times do
  print '.'
  user = { user_id: SecureRandom.uuid, email: Faker::Internet.email, encrypted_password: Digest::SHA1.hexdigest(Faker::Internet.password) }
  CSV.open("data/users.csv", "a") { |csv_out| csv_out << user.values }
  rand(stores_per_user).times do
    store = { store_id: SecureRandom.uuid, user_id: user[:user_id], name: Faker::Superhero.name, category: categories[rand(categories.size)] }
    CSV.open("data/stores.csv", "a") { |csv_out| csv_out << store.values }
    products = []
    rand(products_per_store).times do
      product = { store_id: store[:store_id], product_id: SecureRandom.uuid, name: Faker::Commerce.product_name, description: Faker::Lorem.sentence, product_details: { color: Faker::Commerce.color }.to_json, price: Faker::Commerce.price.to_f }
      CSV.open("data/products.csv", "a") { |csv_out| csv_out << product.values }
      products << product
    end
    orders = []
    rand(orders_per_store).times do
      order = { store_id: store[:store_id], order_id: SecureRandom.uuid, state: states[rand(states.size)], total_amount: 0, shipping_address: fake_address, billing_address: fake_address, shipping_info: { carrier: 'UPS' }.to_json, ordered_at: Faker::Time.backward(30, :evening) }
      rand(line_items_per_order).times do
        product = products[rand(products.size)]
        quantity = rand(1..10).to_i + 1
        line_item = { store_id: store[:store_id], order_id: order[:order_id], product_id: product[:product_id], quantity: quantity, line_amount: product[:price] * quantity }
        order[:total_amount] += line_item[:line_amount]
        CSV.open("data/line_items.csv", "a") { |csv_out| csv_out << line_item.values }
      end
      CSV.open("data/orders.csv", "a") { |csv_out| csv_out << order.values }
    end
  end
end
