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
        args.time_since_start / (60 * 60 * 24), ## convert to seconds 
        args.num_sold, 
        args.initial_price / (10 ** 18), ## scale decimals 
        args.per_period_price_decrease / (10 ** 18), ## scale decimals 
        args.logistic_scale / (10 ** 18), ## scale decimals 
        args.time_scale / (10 ** 18), ## scale decimals 
        0
    )
    price *= (10 ** 18)
    encode_and_print(price)

def calculate_pages_price(args): 
    pricer = Pricer()
    price = pricer.compute_page_price(
        args.time_since_start / (60 * 60 * 24), ## convert to seconds 
        args.num_sold, 
        args.initial_price / (10 ** 18), ## scale decimals 
        args.per_period_price_decrease / (10 ** 18), ## scale decimals 
        args.logistic_scale / (10 ** 18), ## scale decimals 
        args.time_scale / (10 ** 18), ## scale decimals 
        0,
        args.per_period_post_switchover / (10 ** 18), ## scale decimals 
        args.switchover_time / (10 ** 18)
    )
    price *= (10 ** 18)
    encode_and_print(price)

def encode_and_print(price):
    enc = encode_single('uint256', int(price))
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
    parser.add_argument("--per_period_post_switchover", type=int)
    parser.add_argument("--switchover_time", type=int)
    return parser.parse_args()

if __name__ == '__main__':
    args = parse_args() 
    main(args)
