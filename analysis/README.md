# Gobblers Analysis

Additional analysis for Art Gobblers, including python implementations for differential fuzzing and automated theorem proofs of certain key assumptions.

## Differential fuzzing

In order to run differential fuzz tests, first install requirements with:

```
pip install -r requirements.txt
```

Then run FFI tests from the root directory:

```
FOUNDRY_PROFILE="FFI" forge test
```

## Automated theorem proving

In order to run, first install a theorem prover such as [Z3](https://github.com/Z3Prover/z3).

Then, run the following command:

```
z3 smt/goo_pooling.smt2
```
