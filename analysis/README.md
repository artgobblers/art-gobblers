# Gobblers Analysis

Additional analysis for gobblers, including python implementations for differential testing, as well as automatic theorem proving.


## Differential testing

In order to run differential tests, first install requirements with

```
pip install -r requirements.txt
```

Then run FFI tests from parent directory

```
FOUNDRY_PROFILE="FFI" forge test
```

## SMT

In order to run, first install a theorem prover such as [Z3](https://github.com/Z3Prover/z3)

Then, run the following command: 

```
z3 smt/goo_pooling.smt2
```

