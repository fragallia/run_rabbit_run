require 'daemons'

Daemons.run('services/assembler.rb', :app_name => '[ruby] Assembler Service', :multiple => true)
