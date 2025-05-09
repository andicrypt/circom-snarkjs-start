# Compile circuit 

```
circom first_circuit.circom --r1cs --wasm --sym
```

# Setup 
```
npx snarkjs groth16 setup first_circuit.r1cs powersOfTau28_hez_final_08.ptau first_circuit_0000.zkey  
npx snarkjs zkey contribute first_circuit_0000.zkey first_circuit_final.zkey --name="My Contribution" -v
```

# Gen witness 

```
node first_circuit_js/generate_witness.js first_circuit_js/first_circuit.wasm inputs.json witness.wtns
```

# Export verification key

```
npx snarkjs zkey export verificationkey first_circuit_final.zkey verification_key.json
```

# Prove 
```
npx snarkjs groth16 prove first_circuit_final.zkey witness.wtns proof.json public.json
```

# Verify 
```
npx snarkjs groth16 verify verification_key.json public.json proof.json
```