function increase_tariff!(consumer::Consumer)
    
    consumer.tariff.e_cost = [(block[1],block[2]*(1+consumer.tariff.increase)) for block in consumer.tariff.e_cost]
    consumer.tariff.p_cost = [(block[1],block[2]*(1+consumer.tariff.increase)) for block in consumer.tariff.p_cost]
	consumer.tariff.access = consumer.tariff.access*(consumer.tariff.access_increase)
    
end

function increase_tariff!(tariff::Tariff)
    
    tariff.e_cost = [(block[1],block[2]*(1+tariff.increase)) for block in tariff.e_cost]
    tariff.p_cost = [(block[1],block[2]*(1+tariff.increase)) for block in tariff.p_cost]
    
end