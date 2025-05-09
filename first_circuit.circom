pragma circom 2.1.0;
template HelloWorld() {
    signal input in;
    signal output out;
    out <== in;
}

component main = HelloWorld();