module Prices
  module Calculator
    extend self

    def calculate(rules, start_date, end_date)
      basic = (rules.fetch('basic', []).find { |x| x['from'] <= start_date && x['to'] >= start_date } || {})['price']
      if basic
        res = basic

        seasonal = rules.fetch('seasonal', []).find { |x| x['from'] <= start_date && x['to'] >= start_date }
        if seasonal
          if seasonal['type'] == 'precents'
            res += res * seasonal['value'] / 100
          end
        end

        seasonal = rules.fetch('start', []).find { |x| false }
        seasonal = rules.fetch('weekday', []).find { |x| false }


        res
      else
        nil
      end
    end
  end
end
