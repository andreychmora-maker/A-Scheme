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

/* PART 2: ALGEBRAIC ENGINE (Extended Non-Systematic RS [256, 192, 65]_256) */
F<w> := GaloisField(256);
n_len := 256;
k_dim := 192;
d_min := 65;
aleph := 31; // Unique decoding radius on cyclic [255, 192, 64] core

// Second argument in ReedSolomonCode(F, d) is the designed distance d = 64
C_std := ReedSolomonCode(F, d_min - 1); // Standard cyclic [255, 192, 64]_256
G_std := GeneratorMatrix(C_std);        // Systematic [I_192 | P] (192 x 255)

// Non-systematic scrambling matrix S in GL_192(F_256)
repeat
    S_mat := RandomMatrix(F, k_dim, k_dim);
until IsInvertible(S_mat);
S_inv := S_mat^-1;

// Combined non-systematic generator matrix (192 x 255) for the cyclic core
G_ns := S_mat * G_std;

FieldElementToBinVec := function(element)
    return [ Integers() ! x : x in ElementToSequence(element) ];
end function;

BinVecToFieldElement := function(bin_vec)
    return F ! [ GF(2) ! x : x in bin_vec ];
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
printf "\n--- STARTING FAST PROTOCOL BENCHMARK ([256, 192, 65]_256) ---\n";
msg_vec := Random(VectorSpace(F, k_dim));

// 1. Encode 255-symbol non-systematic RS codeword and append 256-th overall parity symbol
cw_255 := Eltseq(msg_vec * G_ns);
codeword := Append(cw_255, &+cw_255);

error_vector := [F!0 : i in [1..n_len]];
for i in [1..aleph] do 
    repeat err_val := Random(F); until err_val ne F!0;
    error_vector[i] := err_val; 
end for;

receiver_share := [Random(F) : i in [1..n_len]];
sender_share := [codeword[i] + error_vector[i] + receiver_share[i] : i in [1..n_len]];
received_homomorphic := [F!0 : i in [1..n_len]];

printf "\n[!] Executing Homomorphic XOR (%o ops)...\n", n_len;
t_eval := Cputime();
for chunk in [1..n_len] do
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
received_255 := VectorSpace(F, 255) ! received_homomorphic[1..255];

iterations := 10000;
c_start := ClockCycles();
for i in [1..iterations] do
    success, decoded_255 := Decode(C_std, received_255);
end for;
c_end := ClockCycles();

avg_cycles := (c_end - c_start) div iterations;

if success then
    // Reconstruct the 256-th overall parity symbol
    recovered_parity := &+Eltseq(decoded_255);
    // Since G_std = [I_192 | P] is systematic, the first k_dim coordinates are (msg_vec * S_mat)
    scrambled_rec := VectorSpace(F, k_dim) ! Eltseq(decoded_255)[1..k_dim];
    recovered_msg := scrambled_rec * S_inv;
    
    printf "RS Status: SUCCESS (Cleared %o errors, Parity Verified: %o)\n", 
           aleph, recovered_parity eq codeword[256];
    printf "Algebraic Decode Time: %o CPU Cycles (Avg)\n", avg_cycles;
    printf "Payload Integrity Verification: %o\n", recovered_msg eq msg_vec;
else
    printf "RS Decoder Status: FAILED\n";
end if;
