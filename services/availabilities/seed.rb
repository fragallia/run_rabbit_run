require 'rubygems'
require 'mongo'
require 'date'

@conn = Mongo::Connection.new
@db   = @conn['ht2']
@coll = @db['availabilities']

def generate_documents(property_id)
  res = [] 
  date = Date.today
  Random.rand(10).times do | i |
    availability   = Random.rand(100)
    unavailability = Random.rand(50) + 1
    res << {
      :from => date.strftime('%Y%m%d').to_i,
      :to => (date + availability).strftime('%Y%m%d').to_i
    }
    date += availability + unavailability
  end

  {
    :_id => property_id,
    :availabilities => res,
    :location => generate_locations(),
    :sqs => Random.rand(100) + 1
  }
end

def generate_locations
  res = []
  (Random.rand(4) + 1).times do | i |
    res << Random.rand(10000)
  end

  res
end

@coll.drop
1000000.times do |i|
  puts i if i % 10000 == 0
  @coll.insert(generate_documents(i+1))
end

