module FedexRatesGem
  class Rates
    class << self
      def get(credentials, quote_params)
        response = FedexRatesGem::Connection.connection(credentials, quote_params)
      end
    end
  end
end