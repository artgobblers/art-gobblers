# Gobblers Analysis

Directory for Gobbler FFI fuzz testing.

## Running

In order to run correctness tests, first install requirements with

```
pip install -r requirements.txt
```

Then run FFI tests with

```
FOUNDRY_PROFILE="FFI" forge test
```
