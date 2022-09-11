import math
import numpy as np


class Pricer: 
    
    def compute_gobbler_price(self, time_since_start, num_sold, initial_price, per_period_price_decrease, logistic_scale, time_scale, time_shift):
       return self.compute_vrgda_price(time_since_start, num_sold, initial_price, per_period_price_decrease, logistic_scale, time_scale, time_shift)

    def compute_page_price(self, time_since_start, num_sold, initial_price, per_period_price_decrease, logistic_scale, time_scale, time_shift,  per_period_post_switchover, switchover_time):
        initial_value = logistic_scale/ (1 +math.exp(time_scale * time_shift))
        sold_by_switchover = logistic_scale / (1 + math.exp(-1 * time_scale * (switchover_time - time_shift))) - initial_value
        if num_sold < sold_by_switchover:
            return self.compute_vrgda_price(time_since_start, num_sold, initial_price, per_period_price_decrease, logistic_scale, time_scale, time_shift)
        else: 
            f_inv = (num_sold - sold_by_switchover) / per_period_post_switchover + switchover_time
            return initial_price * math.exp(-math.log(1 - per_period_price_decrease) * (f_inv - time_since_start))

    def compute_vrgda_price(self, time_since_start, num_sold, initial_price, per_period_price_decrease, logistic_scale, time_scale, time_shift):
        initial_value = logistic_scale / (1 + math.exp(time_scale * time_shift))
        logistic_value = num_sold + initial_value
        price = (1 - per_period_price_decrease) ** (time_since_start - time_shift + (math.log(-1 + logistic_scale / logistic_value) / time_scale)) * initial_price
        return price
