pragma circom 2.1.6;

include "circomlib/poseidon.circom";
include "https://github.com/iden3/circomlib/blob/master/circuits/gates.circom";
include "https://github.com/iden3/circomlib/blob/master/circuits/comparators.circom";

// check that value in row align from 1-9 strictly.
template CheckRow() {
    signal input row[9];
    
    component xor_ops[36];
    component conv_ops[10];

    signal output out;
    
    signal xor_out[10][4];

    conv_ops[0] = Num2Bits(4);
    
    1 ==> conv_ops[0].in;
    xor_out[0][0] <==  conv_ops[0].out[0];
    xor_out[0][1] <==  conv_ops[0].out[1];
    xor_out[0][2] <==  conv_ops[0].out[2];
    xor_out[0][3] <==  conv_ops[0].out[3];

    for(var i = 0; i < 9; i++) {
        conv_ops[i+1] = Num2Bits(4);
        row[i] ==> conv_ops[i+1].in;
        
        for (var j = 0; j < 4; j++) {
            xor_ops[i * 4 + j] = XOR();
            xor_out[i][j] ==> xor_ops[i * 4 + j].a;
            conv_ops[i+1].out[j] ==> xor_ops[i *  4 + j].b; 
            
            xor_ops[i * 4 + j].out ==> xor_out[i + 1][j];
        }
    }

    xor_out[9][0] === 0;
    xor_out[9][1] === 0;
    xor_out[9][2] === 0;
    xor_out[9][3] === 0;

    out <== xor_out[9][0] + xor_out[9][1] + xor_out[9][2] + xor_out[9][3];
}

// check that each value in range 1-9
template BoundCheck() {
    signal input solution[9][9];

    signal output out;

    component geq[81];
    component leq[81];

    signal valid[81];

    var collect = 0;

    for (var i = 0; i < 9; i++) {
        for (var j = 0; j < 9; j++) {
            geq[i * 9 + j] = GreaterEqThan(4);
            leq[i * 9 + j] = LessEqThan(4);
            
            geq[i * 9 + j].in[0] <== solution[i][j];
            geq[i * 9 + j].in[1] <== 1;

            leq[i * 9 + j].in[0] <== solution[i][j];
            leq[i * 9 + j].in[1] <== 9;

            // if out is 1, then leq/geq is true
            // if out is 0, then leq/geq is false

            geq[i * 9 + j].out === 1;
            leq[i * 9 + j].out === 1;

            // both geq and leq be == 1
            valid[i * 9 + j] <== geq[i * 9 + j].out * leq[i * 9 + j].out;
            collect += valid[i * 9 + j];
        }
    }

    collect === 81;
    out <== collect;
}

// Check public input in table aligns with values in solution.
template CheckPublicInput() {
    signal input table[9][9];
    signal input solution[9][9];
    signal output out;
    
    component izr[81]; // isZero
    component ieq[81]; // isEqual

    signal valid[81];

    var collect = 0;

    for (var i = 0; i < 9; i++) {
        for (var j = 0; j < 9; j++) {
            izr[i * 9 + j] = IsZero();
            izr[i * 9 + j].in <== table[i][j];
            
            ieq[i * 9 + j] = IsEqual();
            ieq[i * 9 + j].in[0] <== solution[i][j]; 
            ieq[i * 9 + j].in[1] <== table[i][j];
            
            // result must be (zero || equal)
            valid[i * 9 + j] <== 1 - (1 - izr[i * 9 + j].out) * (1 - ieq[i * 9 + j].out);
            collect += valid[i * 9 + j];
        }
    }

    collect === 81;
    out <== collect;
}

template SudokuSolver () {
    signal input table[9][9];
    signal input solution[9][9];

    component rowCheck[9];
    for (var i = 0; i < 9; i++) {
        rowCheck[i] = CheckRow();
        solution[i] ==> rowCheck[i].row;
        rowCheck[i].out === 0;
    }

    component boundCheck = BoundCheck();
    boundCheck.solution <== solution;
    boundCheck.out === 81;

    component publicInputCheck = CheckPublicInput();
    publicInputCheck.table <== table;
    publicInputCheck.solution <== solution;
    publicInputCheck.out === 81;
}

component main = SudokuSolver();

/* INPUT = {
    "table": [
        [5, 3, 0, 0, 7, 0, 0, 0, 0],
        [6, 0, 0, 1, 9, 5, 0, 0, 0],
        [0, 9, 8, 0, 0, 0, 0, 6, 0],
        [8, 0, 0, 0, 6, 0, 0, 0, 3],
        [4, 0, 0, 8, 0, 3, 0, 0, 1],
        [7, 0, 0, 0, 2, 0, 0, 0, 6],
        [0, 6, 0, 0, 0, 0, 2, 8, 0],
        [0, 0, 0, 4, 1, 9, 0, 0, 5],
        [0, 0, 0, 0, 8, 0, 0, 7, 9]
    ],
    "solution": [
        [5, 3, 4, 6, 7, 8, 9, 1, 2],
        [6, 7, 2, 1, 9, 5, 3, 4, 8],
        [1, 9, 8, 3, 4, 2, 5, 6, 7],
        [8, 5, 9, 7, 6, 1, 4, 2, 3],
        [4, 2, 6, 8, 5, 3, 7, 9, 1],
        [7, 1, 3, 9, 2, 4, 8, 5, 6],
        [9, 6, 1, 5, 3, 7, 2, 8, 4],
        [2, 8, 7, 4, 1, 9, 6, 3, 5],
        [3, 4, 5, 2, 8, 6, 1, 7, 9]
    ]
} */