from pricer import Pricer
from eth_abi import encode_single
import argparse

def main(args): 
    if (args.type == 'gobblers'): 
        calculate_gobblers_price(args)
    elif (args.type == 'pages'):
        calculate_pages_price(args)
    
def calculate_gobblers_price(args): 
    pricer = Pricer()
    price = pricer.compute_gobbler_price(
        args.time_since_start, 
        args.num_sold, 
        args.initial_price, 
        args.per_period_price_decrease, 
        args.logistic_scale, 
        args.time_scale, 
        args.time_shift
    )
    encode_and_print(price)

def calculate_pages_price(args): 
    print("todo")

def encode_and_print(price):
    enc = encode_single('uint256', price)
    ## append 0x for FFI parsing 
    print("0x" + enc.hex())

def parse_args(): 
    parser = argparse.ArgumentParser()
    parser.add_argument("type", choices=["gobblers", "pages"])
    parser.add_argument("--time_since_start", type=int)
    parser.add_argument("--num_sold", type=int)
    parser.add_argument("--initial_price", type=int)
    parser.add_argument("--per_period_price_decrease", type=int)
    parser.add_argument("--logistic_scale", type=int)
    parser.add_argument("--time_scale", type=int)
    parser.add_argument("--time_shift", type=int)
    return parser.parse_args()

if __name__ == '__main__':
    args = parse_args() 
    main(args)