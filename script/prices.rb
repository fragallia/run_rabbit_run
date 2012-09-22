require 'daemons'

Daemons.run('services/prices.rb', :app_name => '[ruby] Prices Service', :multiple => true)
