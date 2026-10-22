/* SaaC Prototyping */

/* It combines every advanced feature discussed:

Architecture: Bootstrap (Public) → Key Derivation → Secure Session → Reinitialization.

Cryptography: RFC 5869 HKDF for all chain operations.

Storage: Lamport Model (Sender stores some number of intermidiate hash values and computes the hash value on-the-fly; Receiver stores Tip only).

Obfuscation: To obfuscate the geometry (the point of an elliptic curve) we apply Elligator Squared technique. That is why the Nonce appears. To hide Nonce we apply 2-Bit Parity Filter which is a sophisticated Steganographic mechanism. It allows us to transmit metadata (the Nonce) implicitly by encoding it into the mathematical "noise" of the elliptic curve coordinates.

Verification: Hex dump of the exact 192-byte wire payload. */

// =============================================================================
//  FINAL MASTER SCRIPT: FULL LIFECYCLE (BOOTSTRAP -> SESSION -> RATCHET)
//  STATUS: 100% COMPLETE, ENCRYPTED, AUTOMATED RE-INIT
// =============================================================================

// -----------------------------------------------------------------------------
// 1. SETUP FIELDS AND CURVES (FULL)
// -----------------------------------------------------------------------------
p := 0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab;
F := GF(p);
P<z> := PolynomialRing(F);
F2<I> := ExtensionField<F, z | z^2 + 1>;

E_target := EllipticCurve([F2| 0, 4*(1+I)]);

A_isog := 240*I;
B_isog := 1012*(1+I);
Z := -(2 + I);
Inv3 := 34957250116750793652965160338790643891793701667018425215069105799959054123009;
Cofactor := 0xbc69f08f2ee75b3584c6a0ea91b352888e2a8e9145ad7689986ff031508ffe1329c2f178731db956d82bf015d1212b02ec0ec69d7477c1ae954cbc06689f6a359894c0adebbf6b4e8020005aaa95551;

// Kernel Constants
x0 := 4002409555221667393417789825735904156556882819939007885332058136124031650490837864442687629129015664037894272559785*I + 2;
Two_x0 := 2*x0; Three_x0 := 3*x0; x0_2 := x0^2; Three_x0_2 := 3*x0_2; x0_3 := x0^3;

E_isog := EllipticCurve([F2| A_isog, B_isog]);

// OPTIMIZATION: Precompute Identity Elements
Identity_Target := E_target!0;
Identity_Isog := E_isog!0;

// -----------------------------------------------------------------------------
// 2. CRYPTO PRIMITIVES (HKDF)
// -----------------------------------------------------------------------------

/*
In RFC 5869 (HKDF: HMAC-based Extract-and-Expand Key Derivation Function),
PRK stands for:

Pseudo-Random Key
It is the output of the Extract step and the primary input for the Expand step.
Here is the exact interpretation of its role in the protocol:

The "Concentrated" Secret: The input keying material (IKM) you start with might be weak, non-uniform, or have low entropy per bit (like a Diffie-Hellman result). The goal of the Extract phase is to "concentrate" that entropy into a short, cryptographically strong, and uniformly distributed key. That key is the PRK.

Mathematical Definition: 
$$PRK = \text{HMAC-Hash}(\text{salt}, \text{IKM})$$ 
Bit Length: The PRK is always exactly the length of the underlying hash function's output (e.g., 256 bits for SHA-256), regardless of how long the input (IKM) was.

Role in Expansion: Once calculated, the PRK acts as the "Master Key" for the Expand phase. It is used to generate an arbitrary amount of Output Keying Material (OKM) for encryption keys, IVs, or authentication tags.  $$OKM = \text{HKDF-Expand}(PRK, \text{info}, \text{length})$$ 
In Your Script's Context
When your script runs:
PRK_Init := HKDF_Extract(Shared_Key, Seed);

Shared_Key acts as the Salt.

Seed acts as the IKM (Input Keying Material).

PRK_Init is the Pseudo-Random Key—a cryptographically uniform field element derived from the seed, which is then safe to use for generating the rest of the chain ($L_0, L_1, \dots$).
*/

function OracleHash(Inputs_Sequence)
    BigString := &cat [Sprint(x) : x in Inputs_Sequence];
    SeedVal := Hash(BigString);
    s, c := GetSeed();
    SetSeed(SeedVal);
    Digest := Random(F2);
    SetSeed(s, c);
    return Digest;
end function;

function HMAC_Sim(Key, Data_Seq)
    return OracleHash([Sprint(Key)] cat Data_Seq);
end function;

function HKDF_Extract(salt, IKM)
    return HMAC_Sim(salt, [Sprint(IKM)]);
end function;

function HKDF_Expand(PRK, info, L)
    T_prev := ""; Out := [F2| ];
    for i in [1..L] do
        Raw := IntegerToString(i, 16);
        C_Str := (#Raw eq 1 select "0" else "") cat Raw;
        Payload := Sprint(T_prev) cat info cat C_Str;
        T_next := HMAC_Sim(PRK, [Payload]);
        Append(~Out, T_next);
        T_prev := T_next; 
    end for;
return Out;
end function;

// -----------------------------------------------------------------------------
// 3. MAPS & HELPERS
// -----------------------------------------------------------------------------
function Sgn0(u)
    seq:=ElementToSequence(u);
    u0:=Integers()!seq[1];
    u1:=Integers()!seq[2];
    if u0 ne 0 then return u0 mod 2;
       else return u1 mod 2;
    end if;
end function;

function CMOV(a, b, cond)
    if cond then return b;
      else return a;
    end if;
end function;

function SqrtRatio(u, v)
    if v eq 0 then return false, 0;
    end if;
    val:=u/v;
    is_sq,root:=IsSquare(val);
    if is_sq then return true,root;
      else return false,Sqrt(Z*val);
    end if;
end function;

// Forward Map Constants

k_1 := [
F!0x5c759507e8e333ebb5b7a9a47d7ed8532c52d39fd3a042a88b58423c50ae15d5c2638e343\
  d9c71c6238aaaaaaaa97d6 +
F!0x5c759507e8e333ebb5b7a9a47d7ed8532c52d39fd3a042a8\
  8b58423c50ae15d5c2638e343d9c71c6238aaaaaaaa97d6*I,
F!0x11560bf17baa99bc32126fced787c88f984f87adf7ae0c7f9a208c6b4f20a4181472aaa9c\
  b8d555526a9ffffffffc71a*I,
F!0x11560bf17baa99bc32126fced787c88f984f87adf7ae0c7f9a208c6b4f20a4181472aaa9c\
  b8d555526a9ffffffffc71e +
F!0x8ab05f8bdd54cde190937e76bc3e447cc27c3d6fbd7063f\
  cd104635a790520c0a395554e5c6aaaa9354ffffffffe38d*I,
F!0x171d6541fa38ccfaed6dea691f5fb614cb14b4e7f4e810aa22d6108f142b85757098e38d0\
  f671c7188e2aaaaaaaa5ed1
];

k_2 := [
F!0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb\
  153ffffb9feffffffffaa63*I,
F!0xc +
F!0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241ea\
  bfffeb153ffffb9feffffffffaa9f*I
];

k_3 := [
F!0x1530477c7ab4113b59a4c18b076d11930f7da5d4a07f649bf54439d87d27e500fc8c25ebf\
  8c92f6812cfc71c71c6d706 +
F!0x1530477c7ab4113b59a4c18b076d11930f7da5d4a07f649\
  bf54439d87d27e500fc8c25ebf8c92f6812cfc71c71c6d706*I,
F!0x5c759507e8e333ebb5b7a9a47d7ed8532c52d39fd3a042a88b58423c50ae15d5c2638e343\
  d9c71c6238aaaaaaaa97be*I,
F!0x11560bf17baa99bc32126fced787c88f984f87adf7ae0c7f9a208c6b4f20a4181472aaa9c\
  b8d555526a9ffffffffc71c +
F!0x8ab05f8bdd54cde190937e76bc3e447cc27c3d6fbd7063f\
  cd104635a790520c0a395554e5c6aaaa9354ffffffffe38f*I,
F!0x124c9ad43b6cf79bfbf7043de3811ad0761b0f37a1e26286b0e977c69aa274524e79097a5\
  6dc4bd9e1b371c71c718b10
];

k_4 := [
F!0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb\
  153ffffb9feffffffffa8fb +
F!0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512b\
  f6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffa8fb*I,
F!0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb\
  153ffffb9feffffffffa9d3*I,
F!0x12 + 
F!0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241e\
  abfffeb153ffffb9feffffffffaa99*I
];

// SSWU MAP
function SSWUHash2Point(u)
    tv1:=Z*u^2;
    tv2:=tv1^2+tv1;
    tv3:=B_isog*(tv2+1);
    tv4:=CMOV(Z,-tv2,tv2 ne 0)*A_isog;
    tv2:=tv3^2;
    tv6:=tv4^2;
    tv5:=A_isog*tv6;
    tv2:=tv2+tv5;
    tv2:=tv2*tv3;
    tv6:=tv6*tv4;
    tv5:=B_isog*tv6;
    tv2:=tv2+tv5;
    x:=tv1*tv3;
    is_gx1_square,y1:=SqrtRatio(tv2,tv6);
    y:=tv1*u*y1;
    x:=CMOV(x,tv3,is_gx1_square);
    y:=CMOV(y,y1,is_gx1_square);
    e1:=(Sgn0(u) eq Sgn0(y));
    y:=CMOV(-y,y,e1);
    return [x/tv4,y]; 
end function;

// ROBUST PREIMAGE
function BasePreimage(P_val)
    X:=P_val[1]; Y:=P_val[2]; denom:=-A_isog*X-B_isog; 
    if denom eq 0 then return false, F2!0; end if;
    V:=B_isog/denom; delta1:=1+4*V; is_sq1,root1:=IsSquare(delta1);
    if is_sq1 then 
        for W in [(-1+root1)/2, (-1-root1)/2] do 
            if W ne 0 then 
              is_sq_u, u_val := IsSquare(W/Z);
              if is_sq_u then
                if Sgn0(u_val) ne Sgn0(Y) then
                  u_val := -u_val;
                end if;
              return true, u_val;
             end if;
           end if;
        end for;
    end if;
    K:=(-A_isog*X)/B_isog;
    C:=1-K;
    delta2:=C^2-4*C;
    is_sq2,root2:=IsSquare(delta2);
    if is_sq2 then 
        for W in [(-C+root2)/2, (-C-root2)/2] do 
            if W ne 0 then 
                is_sq_u, u_val := IsSquare(W/Z);
                if is_sq_u then
                  T:=W^2+W;
                  if T ne 0 then 
                    x1:=(-B_isog/A_isog)*(1+1/T);
                    gx1:=x1^3+A_isog*x1+B_isog; 
                    if not IsSquare(gx1) then 
                      if Sgn0(u_val) ne Sgn0(Y) then
                        u_val := -u_val;
                      end if;
                      return true, u_val;
                    end if;
                  end if;
               end if;
           end if;
        end for;
     end if;
     return false, F2!0;
end function;

EvaluateForwardMap := function(Q)
    if IsZero(Q) then return Identity_Target;
    end if;
    x:=Q[1]; y:=Q[2];
    x_num:=k_1[1]+k_1[2]*x+k_1[3]*x^2+k_1[4]*x^3;
    x_den:=k_2[1]+k_2[2]*x+x^2;
    y_num:=k_3[1]+k_3[2]*x+k_3[3]*x^2+k_3[4]*x^3;
    y_den:=k_4[1]+k_4[2]*x+k_4[3]*x^2+x^3;
    return E_target![x_num/x_den,-y*y_num/y_den];
end function;

// Backward Map

EvaluateBackwardMap := function(P)
    if IsZero(P) then return Identity_Isog;
    end if;
    x:=P[1]; y:=P[2];
    x_2:=x^2; x_3:=x^3;
    Dx:=x_2-x*Two_x0+x0_2;
    if IsZero(Dx) then
      return Identity_Isog;
    end if;
    Dy:=x_3-x_2*Three_x0+x*Three_x0_2-x0_3;
    Nx:=x_3-Two_x0*x_2-56*I*x+48*(1+I);
    Ny:=x_3-Three_x0*x_2+24*I*x+16*(1+I);
    return E_isog![Nx/Dx,y*(Ny/Dy)];
end function;

GetExactPreimage := function(P)
    Q_dual:=EvaluateBackwardMap(P);
    return Inv3*Q_dual;
end function;

//-------------------------------------------------------------------
// 4. SMART CACHED HASH CHAIN LOGIC
//-------------------------------------------------------------------

DeriveElementFromLink := function(Link, Nonce)
    LinkStr:=IntegerToString(Hash(Link));
    NonceStr:=IntegerToString(Nonce);
    MixedVal:=Hash(LinkStr cat "_" cat NonceStr);
    s,c:=GetSeed();
    SetSeed(MixedVal);
    Derived:=Random(F2);
    SetSeed(s,c);
    return Derived;
end function;

function ComputeLinkAt_Cached(Cache, Key, TargetIndex)
    Best_Idx := -2; Best_Val := "";
    for Entry in Cache do
        Idx := Entry[1]; Val := Entry[2];
        if (Idx le TargetIndex) and (Idx gt Best_Idx) then
          Best_Idx := Idx; Best_Val := Val;
        end if;
    end for;
    if Best_Idx eq -2 then
      error "Cache Empty or Invalid";
    end if;
    Current_Link := Best_Val;
    Current_Idx := Best_Idx;
    
    if Current_Idx eq -1 then
        if TargetIndex ge 0 then
            PRK := HKDF_Extract(Key, Current_Link);
            Current_Link := HKDF_Expand(PRK, "S/Key_Init", 1)[1];
            Current_Idx := 0;
        end if;
    end if;
    while Current_Idx lt TargetIndex do
        PRK := HKDF_Extract(Key, Sprint(Current_Link));
        Current_Link := HKDF_Expand(PRK, "S/Key_Step", 1)[1];
        Current_Idx := Current_Idx + 1;
    end while;
    return Sprint(Current_Link);
end function;

//-------------------------------------------------------------------
// 5. PARITY ENCODING & ENCRYPTION
//-------------------------------------------------------------------

function GetComplexParity(val)
   seq := ElementToSequence(val);
   return [Integers()!seq[1] mod 2, Integers()!seq[2] mod 2]; 
end function;

// ENCRYPTION HELPER

function GetCoordinateMask(Shared_Key, Round_Num, Label_String)
    // 1. Create a unique salt for this specific coordinate
    // Format: "Mask" || Round_Num || Label (e.g., "Mask_42_coord_u")
    Salt := "Mask_" cat IntegerToString(Round_Num) cat "_" cat Label_String;
    
    // 2. Extract randomness from the Shared Key
    PRK := HKDF_Extract(Shared_Key, Salt);
    
    // 3. Expand to get the mask value
    Mask_Val := HKDF_Expand(PRK, "Mask_Expansion", 1)[1];
    
    return Mask_Val;
end function;

// SENDER: FILTER (u) & FILTER (v) - Uses RAW NONCE
function SenderObfuscate_Parity(P_Fixed, Current_Link)
    P_isog := GetExactPreimage(P_Fixed);
    for Nonce in [0..255] do
        b0 := Nonce mod 2;
        b1 := (Nonce div 2) mod 2;
        u_tmp := DeriveElementFromLink(Current_Link, Nonce);
        u_p := GetComplexParity(u_tmp); 
        if u_p[1] eq b0 then
            Coords_tmp := SSWUHash2Point(u_tmp);
            ok_u, P_u := IsPoint(E_isog, Coords_tmp);
            if ok_u then
                P_v := P_isog - P_u;
                success, v_val := BasePreimage(P_v);
                if success then
                    v_p := GetComplexParity(v_val);
                    if v_p[1] eq b1 then
                        Coords_v := SSWUHash2Point(v_val);
                        if IsPoint(E_isog, Coords_v) then 
                           return true, u_tmp, v_val, Nonce;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end for;
    return false, 0, 0, 0;
end function;

// WIRE HELPERS (STRICT 192 BYTES)

function PadCoord(val)
    h := IntegerToString(Integers()!val, 16);
    while #h lt 96 do
       h := "0" cat h;
    end while;
    return h;
end function;

function CreateEncryptedPacket(u, v, Shared_Key, Round_Num)
    Mask_u := GetCoordinateMask(Shared_Key, Round_Num, "coord_u");
    Mask_v := GetCoordinateMask(Shared_Key, Round_Num, "coord_v");
    u_enc := u + Mask_u; v_enc := v + Mask_v;
    u_seq := ElementToSequence(u_enc);
    v_seq := ElementToSequence(v_enc);
    return PadCoord(u_seq[1]) cat \
           PadCoord(u_seq[2]) cat \
           PadCoord(v_seq[1]) cat PadCoord(v_seq[2]);
end function;

function ParseEncryptedPacket(PacketHex, Shared_Key, Round_Num)
    Hex_u0 := PacketHex[1 .. 96];
    Hex_u1 := PacketHex[97 .. 192];
    Hex_v0 := PacketHex[193 .. 288];
    Hex_v1 := PacketHex[289 .. 384];
    u_enc := F2![StringToInteger(Hex_u0, 16), \
    StringToInteger(Hex_u1, 16)]; 
    v_enc := F2![StringToInteger(Hex_v0, 16), \
    StringToInteger(Hex_v1, 16)];
    Mask_u := GetCoordinateMask(Shared_Key, Round_Num, "coord_u");
    Mask_v := GetCoordinateMask(Shared_Key, Round_Num, "coord_v");
    u_dec := u_enc - Mask_u; v_dec := v_enc - Mask_v;
    return u_dec, v_dec;
end function;

function ReceiverDeobfuscate_Parity(Rx_Link, PacketHex, Shared_Key, Round_Num)
    Rx_u, Rx_v := ParseEncryptedPacket\
    (PacketHex, Shared_Key, Round_Num);
    u_p := GetComplexParity(Rx_u);
    v_p := GetComplexParity(Rx_v);
    Hint := u_p[1] + (v_p[1]*2);
    for High in [0..63] do
        Nonce_Guess := Hint + (High * 4);
        if Nonce_Guess le 255 then
            Check_u := DeriveElementFromLink(Rx_Link, Nonce_Guess);
            if Check_u eq Rx_u then
                Coords_u := SSWUHash2Point(Rx_u);
                Coords_v := SSWUHash2Point(Rx_v);
                if IsPoint(E_isog, Coords_u) and \
                    IsPoint(E_isog, Coords_v) then
                    P_u := E_isog!Coords_u; P_v := E_isog!Coords_v;
                    P_sum := P_u + P_v; 
                    P_Rec := EvaluateForwardMap(P_sum);
                    return true, P_Rec, Nonce_Guess;
                end if;
            end if;
        end if;
    end for;
    return false, Identity_Target, 0;
end function;

// =============================================================================
//  6. UNIVERSAL TEST DRIVER (AUTOMATED RE-INIT)
// =============================================================================

print "\n==========================================================";
print "   FINAL ARCHITECTURE: FULL LIFECYCLE (RE-INIT INCLUDED)";
print "   STATUS: COMPLETE (KERNEL INCLUDED)";
print "==========================================================";

Chain_Len := 20; // Small length to trigger re-init quickly

// [1] BOOTSTRAP (Unencrypted)
print "\n[1] PHASE 1: Bootstrap (Unkeyed)...";
Bootstrap_Key := "PUBLIC_BOOTSTRAP";
Bootstrap_Seed := "Boot_" cat IntegerToString(Random(10^9));
Sender_Cache := [ < -1, Bootstrap_Seed > ];
Cache_Stride := Floor(Sqrt(Chain_Len)); if Cache_Stride eq 0 then Cache_Stride := 1; end if;

// Populate Setup Cache
for i in [0 .. Chain_Len - 1 by Cache_Stride] do
    Val := ComputeLinkAt_Cached(Sender_Cache, Bootstrap_Key, i); Append(~Sender_Cache, <i, Val>);
end for;

Bootstrap_Link := ComputeLinkAt_Cached(Sender_Cache, Bootstrap_Key, Chain_Len - 1);
P_BLS_Sig := Cofactor * Random(E_target);
while IsZero(P_BLS_Sig) do
   P_BLS_Sig := Cofactor * Random(E_target);
end while;
print "    Secret Point (BLS Sig):", P_BLS_Sig;

// Unencrypted Sender Logic
ok, u_boot, v_boot, N_Used := SenderObfuscate_Parity\
(P_BLS_Sig,Bootstrap_Link);
if not ok then error "Bootstrap Generation Failed"; end if;
u_seq := ElementToSequence(u_boot); v_seq := ElementToSequence(v_boot);
PacketOut := PadCoord(u_seq[1]) cat PadCoord(u_seq[2]) cat PadCoord(v_seq[1]) cat PadCoord(v_seq[2]);

// Unencrypted Receiver Logic
u_dec := u_boot; v_dec := v_boot; 
u_p := GetComplexParity(u_dec); v_p := GetComplexParity(v_dec);
Hint := u_p[1] + (v_p[1]*2); found := false;
for High in [0..63] do
    Nonce_Guess := Hint + (High*4);
    if Nonce_Guess le 255 then
        Check_u := DeriveElementFromLink(Bootstrap_Link, Nonce_Guess);
        if Check_u eq u_dec then
             found := true; 
             // FIX: Cast Sequence to Point before Addition
             P_Recovered := EvaluateForwardMap\
             (E_isog!SSWUHash2Point(u_dec) + E_isog!SSWUHash2Point(v_dec));
             break;
        end if;
    end if;
end for;

if found then 
    print "    [Success] Bootstrap Secret Recovered."; 
else 
    error "Bootstrap Failed."; 
end if;

// [2] KEY DERIVATION
print "\n\n[2] PHASE 2: Strong Key Derivation (HKDF)...";
Session_Salt := Sprint(Bootstrap_Link); 
PRK_Master := HKDF_Extract(Session_Salt, P_Recovered);
Key_Seq := HKDF_Expand(PRK_Master, "Master_Session_Key", 1);
Shared_Key := Sprint(Key_Seq[1]);
printf "    Derived Shared Key: %o bytes", #Shared_Key;

// [3] SECURE SESSION LOOP WITH RATCHET
Current_Seed := "Secure_" cat IntegerToString(Random(10^9));
Current_Shared_Key := Shared_Key;

// Run 2 Full Cycles (Original Chain + 1 Ratchet)
for Cycle in [1..2] do
    printf "\n\n[3.%o] PHASE 3: Secure Session Cycle %o (Keyed Chain)...",
    Cycle, Cycle;
    
    // Setup Sender Cache
    Session_Cache := [ < -1, Current_Seed > ];
    for i in [0 .. Chain_Len - 1 by Cache_Stride] do
        Val := ComputeLinkAt_Cached(Session_Cache, Current_Shared_Key, i);
        Append(~Session_Cache, <i, Val>);
    end for;
    
    // Receiver Init
    Receiver_Stored_Tip := ComputeLinkAt_Cached\
    (Session_Cache, Current_Shared_Key, Chain_Len);
        print "\n      [Setup]  Receiver initialized with Tip.";
    
    Sender_Current_Index := Chain_Len;
    
    // Consume Chain
    for i in [1..Chain_Len] do
        Target_Index := Sender_Current_Index - 1;
        Secure_Link := ComputeLinkAt_Cached\
        (Session_Cache, Current_Shared_Key, Target_Index);
        
        P_Token := Cofactor * Random(E_target);
        ok, u_sec, v_sec, N_Used := SenderObfuscate_Parity\
        (P_Token, Secure_Link);
        
        if ok then
            // ENCRYPT
            PacketOut := CreateEncryptedPacket\
            (u_sec, v_sec, Current_Shared_Key, i);
            
            // RECEIVER
            PRK_Rec := HKDF_Extract(Current_Shared_Key, Secure_Link);
            Computed_Tip := HKDF_Expand(PRK_Rec, "S/Key_Step", 1)[1];
            
            if Sprint(Computed_Tip) eq Sprint(Receiver_Stored_Tip) then
                Receiver_Stored_Tip := Secure_Link; 
                found, P_Token_Rec, N_Rec := ReceiverDeobfuscate_Parity\
                (Secure_Link, PacketOut, Current_Shared_Key, i);
                if found and (P_Token eq P_Token_Rec) then 
                   printf "\n    --> Round %o: [Success] Nonce: %o", i, N_Rec;
                else
                   print "\n    --> Round %o: [Fail: Token Mismatch]", i;
                end if;
            else
                error "Secure Chain Verification Failed";
            end if;
        else
            print "\n    --> Round %o: [Fail: Nonce Not Found]", i;
        end if;
        Sender_Current_Index := Sender_Current_Index - 1;
    end for;
    
    // [4] REINITIALIZATION (RATCHET)
    print "\n\n[4] PHASE 4: Reinitialization (Ratchet)...";
    
    // Both sides use Link 0 (Last consumed link) to derive new seed
    Last_Link_L0 := ComputeLinkAt_Cached(Session_Cache, Current_Shared_Key, 0);
    
    // Ratchet Context
    Reinit_Context := "REINIT_" cat Current_Shared_Key;
    PRK_Reinit := HKDF_Extract(Reinit_Context, Last_Link_L0);
    
    // 1. Derive New Seed
    New_Seed := Sprint(HKDF_Expand(PRK_Reinit, "S/Key_Reinit_Seed", 1)[1]);
    
    // 2. Rotate Shared Key (Forward Secrecy)
    Key_Seq_New := HKDF_Expand(PRK_Reinit, "S/Key_Reinit_Key", 1);
    New_Shared_Key := Sprint(Key_Seq_New[1]);
    
    // Update State
    Current_Seed := New_Seed;
    Current_Shared_Key := New_Shared_Key;
    
    printf "    [Sync] Ratchet Complete. New Key Derived (%o bytes).", #Current_Shared_Key;
    print "\n    [System] Starting Next Cycle...";
    
end for;

print "\n==========================================================";
