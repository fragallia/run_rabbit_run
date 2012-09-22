require 'rubygems'
require 'riak'
require 'date'

@client = Riak::Client.new(:protocol => "pbc")
@bucket = @client.bucket("service.prices")

def doc(property_id)
  { :_id => property_id}.merge(basic).merge(seasonal).merge(weekday).merge(stay)
end

def basic
  res = { :basic => [] }
  while
    years_count = Random.rand(3)
    if res[:basic].size > 0
      start_year = res[:basic].last[:to].to_date.year + 1
    else
      start_year = Date.today.year
    end

    break if start_year > Date.today.year + 3

    res[:basic] << { :from  => Date.new(start_year, 1, 1).to_time, :to => Date.new(start_year + years_count, 12, 31).to_time, :price => 100 + Random.rand(10) * 10 }
  end

  res
end

def seasonal
  if Random.rand(2) == 1
    res = { :seasonal => [] }

    from = Random.rand(340)
    to = Random.rand(340-from)

    from_date = Date.new(Date.today.year, 1, 1) + from
    to_date = from_date + to

    res[:seasonal] << { :from => from_date.to_time, :to => to_date.to_time, :repeat => 'year', :value => 10, :type => 'precents' }

    res
  else
   {}
  end
end

def weekday
  if Random.rand(3) == 1
    weekend_day_price = Random.rand(10)
    res = {
      :weekday => [
        { :day => 5, :value => weekend_day_price, :type => 'precents' },
        { :day => 6, :value => weekend_day_price, :type => 'precents' },
      ]
    }

    res
  else
    {}
  end
end

def stay
  if Random.rand(3) == 1
    from = Random.rand(3) + 2
    to = from + Random.rand(3)
    res = {
      :stay => [
        { :from => from, :to => to, :value => Random.rand(10) - 5, :type => 'precents' },
      ]
    }

    res
  else
   {}
  end
end

1000000.times do |i|
  puts i if i % 10000 == 0
  object = @bucket.new("property.#{i}")
  object.data = doc(i+1)
  object.store
end

puts 'finishing the seeding'
