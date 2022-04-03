import math
import numpy as np


class Pricer: 
    
    def compute_gobbler_price(self, time_since_start, num_sold, initial_price, per_period_price_decrease, logistic_scale, time_scale, time_shift):
        initial_value = logistic_scale / (1 + math.exp(time_scale * time_shift))
        logistic_value = num_sold + initial_value
        return (1 - per_period_price_decrease) ** (time_since_start - time_shift + (math.log(-1 + logistic_scale / logistic_value) / time_scale)) * initial_price

    def compute_page_price(): 
        pass