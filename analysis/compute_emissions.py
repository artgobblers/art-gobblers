from eth_abi import encode_single
import math
import argparse

def compute_emissions(time, initial_amount, staking_multiple): 
    t1 = math.sqrt(staking_multiple) * time + 2 * math.sqrt(initial_amount)
    final_amount = 0.25 * t1 * t1

    final_amount *= (10 ** 18)
    encode_and_print(final_amount)

def encode_and_print(price):
    enc = encode_single('uint256', int(price))
    ## append 0x for FFI parsing 
    print("0x" + enc.hex())

def parse_args(): 
    parser = argparse.ArgumentParser()
    parser.add_argument("--time", type=int)
    parser.add_argument("--initial_amount", type=int)
    parser.add_argument("--emission_multiple", type=int)
    return parser.parse_args()

if __name__ == '__main__':
    args = parse_args() 
    compute_emissions(
        args.time / (10 ** 18)
        , args.initial_amount / (10 ** 18)
        , args.emission_multiple)
