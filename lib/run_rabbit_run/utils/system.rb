module RRR
  module Utils
    module System
      extend self

      def ip_address
        address = Socket.ip_address_list.detect{|intf| intf.ipv4_private?}
        address ? address.ip_address : '127.0.0.1'
      end
    end
  end
end
