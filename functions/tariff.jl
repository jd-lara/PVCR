function increase_tariff!(consumer::Consumer)
    
    consumer.tariff.e_cost = [(block[1],block[2]*(1+consumer.tariff.increase)) for block in consumer.tariff.e_cost]
    consumer.tariff.p_cost = [(block[1],block[2]*(1+consumer.tariff.increase)) for block in consumer.tariff.p_cost]
    
end