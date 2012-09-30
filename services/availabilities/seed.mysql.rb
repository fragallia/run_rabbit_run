require 'rubygems'
require 'active_record'
require 'date'

ActiveRecord::Base.establish_connection(:adapter => "mysql", :host => "localhost", :database => "ht2")

class Availability < ActiveRecord::Base

end

def generate_documents(property_id)
  res = [] 
  date = Date.today
  Random.rand(10).times do | i |
    availability   = Random.rand(100)
    unavailability = Random.rand(50) + 1
    Availability.create(:property_id => property_id, :from => date, :to => date + availability)
    date += availability + unavailability
  end

  res
end

100000.times do |i|
  puts i if i % 10000 == 0
  generate_documents(i+1)
end

