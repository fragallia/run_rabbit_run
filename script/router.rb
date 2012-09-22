require 'daemons'

Daemons.run('services/router.rb', :app_name => '[ruby] Router Service', :multiple => true)
