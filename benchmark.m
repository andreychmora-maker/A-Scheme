/* Benchmark */
clear;
/* PART 1: CRYPTO PRIMITIVES & O(1) LUT ECDLP */
ElGamalKeys := function(G, q)
    s := Random(q);
    return <s*G, s>;
end function;

ElGamalEncryption := function(PlainText, PublicKey, G, q)
    T := PlainText * G;
    r := Random(q);
    return [r*G, T + r*PublicKey];
end function;

ElGamalDecryption := function(CipherText, SecretKey)
    return CipherText[2] - SecretKey * CipherText[1];
end function;

BinVecReconstruction := function(ScalarValue, k)
    Z := Integers();
    BinVec := [0 : i in [1..k]];
    if ScalarValue eq 0 then return BinVec; end if;
    TmpVec := IntegerToSequence(Z!ScalarValue, 3);
    for i in [1..#TmpVec] do 
        BinVec[i] := TmpVec[i] mod 2; 
    end for;
    return BinVec;
end function;

BuildECDLPTable := function(G, MaxVal)
    Table := AssociativeArray();
    Table[0] := 0; // Point at Infinity
    P := G;
    for i in [1..MaxVal] do
        Table[P[1]] := i;
        P +:= G;
    end for;
    return Table;
end function;

ECDLPByTable := function(Point, Table)
    if IsZero(Point) then return 0; end if;
    return Table[Point[1]];
end function;

/* PART 2: ALGEBRAIC ENGINE (Reed-Solomon & Bridges) */
F<w> := GaloisField(256);
C_std := ReedSolomonCode(F, 128); // [255, 128, 128]

FieldElementToBinVec := function(element)
    seq := ElementToSequence(element);
    bin_seq := [ Integers() ! x : x in seq ];
    while #bin_seq lt 8 do Append(~bin_seq, 0); end while;
    return Reverse(bin_seq);
end function;

BinVecToFieldElement := function(bin_vec)
    le_vec := Reverse(bin_vec);
    if #le_vec eq 0 then return F!0; end if;
    return F ! [ GF(2) ! x : x in le_vec ];
end function;

/* PART 3: DOMAIN SETUP & PRECOMPUTATION */
k := 8; // 1 byte per Homomorphic Operation
printf "\n--- TOY DOMAIN SETUP (Online Calculator) ---\n";
t_start := Cputime();

p := 2^255 - 19;
Px<x> := PolynomialRing(GF(p));
E := EllipticCurve(x^3 + 486662*x^2 + x);
Gy := 0x5f51e65e475f794b1fe122d388b72eb36dc2b281928\
39e4dd6163a5d81312c14;
G := E![GF(p)!0x9, GF(p)!Gy];
q := 2^252 + 27742317777372353535851937790883648493;

Weights := [3^i : i in [0..k-1]];
MaxWeightSum := (&+Weights)*2;
printf "Generating O(1) LUT for N = %o...\n", MaxWeightSum;
LUT := BuildECDLPTable(G, MaxWeightSum);

MyKeys := ElGamalKeys(G, q);
MyPublicKey := MyKeys[1];
MySecretKey := MyKeys[2];
printf "Setup completed in %.3o sec.\n", Cputime(t_start);

/* PART 4: FAST END-TO-END A-SCHEME BENCHMARK */
printf "\n--- STARTING FAST PROTOCOL BENCHMARK ---\n";
msg := [Random(F) : i in [1..128]];
msg_vec := VectorSpace(F, 128) ! msg;
codeword := msg_vec * GeneratorMatrix(C_std);

error_vector := [F!0 : i in [1..255]];
for i in [1..63] do 
    err_val := F!0;
    while err_val eq F!0 do err_val := Random(F); end while;
    error_vector[i] := err_val; 
end for;

receiver_share := [Random(F) : i in [1..255]];
sender_share := [codeword[i] + error_vector[i] + receiver_share[i] : i in [1..255]];
received_homomorphic := [F!0 : i in [1..255]];

printf "\n[!] Executing Homomorphic XOR (255 ops)...\n";
t_eval := Cputime();
for chunk in [1..255] do
    s_bin := FieldElementToBinVec(sender_share[chunk]);
    r_bin := FieldElementToBinVec(receiver_share[chunk]);
    
    SumForSender   := &+[s_bin[i]*Weights[i] : i in [1..k]];
    SumForReceiver := &+[r_bin[i]*Weights[i] : i in [1..k]];
    
    C_Sender   := ElGamalEncryption(SumForSender, MyPublicKey, G, q);
    C_Receiver := ElGamalEncryption(SumForReceiver, MyPublicKey, G, q);
    
    C_Sum := [C_Sender[1] + C_Receiver[1], C_Sender[2] + C_Receiver[2]];
    
    ResultPoint := ElGamalDecryption(C_Sum, MySecretKey);
    ScalarValue := ECDLPByTable(ResultPoint, LUT);
    
    Rec_8 := BinVecReconstruction(ScalarValue, k);
    received_homomorphic[chunk] := BinVecToFieldElement(Rec_8);
end for;
printf "Homomorphic Pipeline Time: %.3o sec.\n", Cputime(t_eval);

// Blind Decoding
printf "\n--- BLIND DECODING & VERIFICATION ---\n";
received_vec := VectorSpace(F, 255) ! received_homomorphic;

iterations := 100;
c_start := ClockCycles();
for i in [1..iterations] do
    success, decoded := Decode(C_std, received_vec);
end for;
c_end := ClockCycles();

avg_cycles := (c_end - c_start) div iterations;

if success then
    recovered_seq := Coordinates(C_std, decoded);
    recovered_msg := VectorSpace(F, 128) ! recovered_seq;
    printf "RS Status: SUCCESS (Cleared %o errors)\n", (MinimumWeight(C_std) - 1) div 2;
    printf "Algebraic Decode Time: %o CPU Cycles (Avg)\n", avg_cycles;
    printf "Payload Integrity Verification: %o\n", recovered_msg eq msg_vec;
else
    printf "RS Decoder Status: FAILED\n";
end if; 
