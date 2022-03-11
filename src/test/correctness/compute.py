import math
from eth_abi import encode_single, decode_single, encode_abi

def gobbler_price(t, sold, p_0, per_period_price_decrease, scale, time_scale, time_shift):
    initial_value = scale / (1 + math.exp(time_scale * time_shift))
    logistic_value = sold + initial_value
    return (1 - per_period_price_decrease) ** (t - time_shift + (math.log(-1 + scale / logistic_value) / time_scale)) * p_0

# enc = encode_single('(uint256, uint256)', [40000, 500000])
enc = encode_single('uint256', 4000)
# print(enc.hex())
bb = b'\x01\x02\x03'
print(enc.hex())
# print(decode_single('uint8', enc))
