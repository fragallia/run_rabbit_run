require 'daemons'

Daemons.run('services/availabilities.rb', :app_name => '[ruby] Availability Service', :multiple => true)
