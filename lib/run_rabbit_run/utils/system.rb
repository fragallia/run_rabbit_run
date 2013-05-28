module RRR
  module Utils
    module System
      extend self

      def ip_address
        Socket.ip_address_list.detect{|intf| intf.ipv4_private?}.ip_address
      end
    end
  end
end
