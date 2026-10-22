/* Optimized Gaudry-Schost */
/* Without lookup table (Montgomery Curve25519) */

clear;
 
/* Start functions definition */
 
ElGamalKeys:=function(G,q)
s:=Random(q);
return <s*G,s>;
end function;

ElGamalEncryption:=function(PlainText,PublicKey,G,q)
T:=PlainText*G; /* Conversion to torsion point */
r:=Random(q);
return [r*G,T+r*PublicKey];
end function;

ElGamalDecryption:=function(CipherText,SecretKey)
return CipherText[2]-SecretKey*CipherText[1];
end function;

BitwiseVectorXOR:=function(BinVec1,BinVec2,k)
   ResultVec:=[BitwiseXor(BinVec1[i],BinVec2[i]) : i  in [1..k by 1]];
return ResultVec;
end function;

BinVecReconstruction:=function(GaudrySchostSolution,k)
Z:=Integers();
BinVec:=[0  :  i  in [1..k by 1]];
TmpVec:=IntegerToSequence(Z!GaudrySchostSolution,3);
for i in [1..#TmpVec] do BinVec[i]:=TmpVec[i] mod 2;
end for;
return BinVec;
end function;

//Gaudry-Schost algorithm

// Add the ~Tag parameter to get the result
GaudrySchostRepresent:=procedure(Point,RandomNumber,~TameWildSet,~TameWildSeq,~Tag)
  InvPoint:=-Point;
  if Point[2] lt InvPoint[2] then
      Represent := Point[2];
      Sign := 0;
      RandNum := RandomNumber;
  else
      Represent := InvPoint[2];
      Sign := 1;
      RandNum := -RandomNumber;
  end if;
  // Generate a short 64-bit tag for Fast Path
  Tag := Hash(Represent);
  // We add only short tags into sets
  Include(~TameWildSet, Tag);
  // We save both the tag and the full data in sequence for Slow Path verification
  Append(~TameWildSeq, <Tag, Represent, RandNum, Sign>);
end procedure;

GaudrySchostResolveCollision:=function(TargetTag, TameSeq, WildSeq)
  Result:=<0, false>;
  
  // We pull out candidates with the match tag
  TameCands := [ x : x in TameSeq | x[1] eq TargetTag ];
  WildCands := [ x : x in WildSeq | x[1] eq TargetTag ];
  for tc in TameCands do
      for wc in WildCands do
          // SLOW PATH: Strict bit-by-bit comparison of full coordinates
          if tc[2] eq wc[2] then 
              Tame_RandNum := tc[3];
              Wild_RandNum := wc[3];
              Wild_Sign    := wc[4];
              
              if Wild_Sign eq 0 then
                  Result := <Tame_RandNum - Wild_RandNum, true>;
              else
                  Result := <Wild_RandNum - Tame_RandNum, true>;
              end if;
              return Result; // A true collision has been found
          end if;
      end for;
  end for;
  
  return Result; // False hash collision, return false
end function;

GaudrySchost:=function(Q,G,TameRange)
  TameSet:={};
  WildSet:={};
  TameSeq:=[];
  WildSeq:=[];
  CompressionRatio:=0.1;
  WildRange:=Floor((TameRange*CompressionRatio)/2);
  i:=0;
  Tag:=0; //Initialize an empty variable for the tag
  
  while true do
    i+:=1;
    RandomNumber:=Random(TameRange);
    Point:=RandomNumber*G;
    
    // We call the procedure by passing the Tag by the link
    GaudrySchostRepresent(Point,RandomNumber,~TameSet,~TameSeq,~Tag);
    // Instant check
    if Tag in WildSet then 
        TameResult := GaudrySchostResolveCollision(Tag, TameSeq, WildSeq);
        if TameResult[2] then Solution:=[TameResult[1],i]; break; end if;
    end if;
    
    i+:=1;
    RandomNumber:=Random(-WildRange,WildRange);
    Point:=Q+RandomNumber*G;
    // We call the procedure
    GaudrySchostRepresent(Point,RandomNumber,~WildSet,~WildSeq,~Tag);
    
    // Instant check
    if Tag in TameSet then 
        WildResult := GaudrySchostResolveCollision(Tag, TameSeq, WildSeq);
        if WildResult[2] then Solution:=[WildResult[1],i]; break; end if;
    end if;
    
  end while;
  return Solution;
end function;

/* End functions definition */

k:=24;
if k le 0 then \
printf "ERROR: the length of a binary vector cannot be zero or negative.\n"; 
quit;
end if;

"-- DOMAIN PARAMETERS SETUP (do it once in real implementation) --";
"-- Loaded from long-term memory when needed --\n";

t:=Cputime();

//Curve25519

p:=0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffed;
printf "p=2^255-19=%h\n",p;
q:=7237005577332262213973186563042994240857116359379907606001950938285454250989;

Px<x>:=PolynomialRing(GF(p));
E:=EllipticCurve(x^3+486662*x^2+x); print E;
Gx:=0x9;
Gy:=0x5f51e65e475f794b1fe122d388b72eb36dc2b28192839e4dd6163a5d81312c14;
G:=E![GF(p)!Gx,GF(p)!Gy];

DomainParSetUpTime:=Cputime(t);

"\n-- Optimal weights --\n";

t:=ClockCycles();
Weights:=[3^i : i in [0..k-1 by 1]];
OptimalWeightsCs:=ClockCycles()-t;
printf "Optimal weights are divisors of %o, namely\n %o.\n", 3^k, Divisors(3^(k-1));

printf "All possible sums of the weights take values from the range: [0,%o].\n", (&+Weights)*2;

"\n-- TEST FOR BITWISE XOR BASED ON ELGamal CRYPTOSYSTEM --\n";

"-- Random generation of binary vectors (big-endian) --\n";
RandomBinVecX:=[Random(1) : i in [1..k by 1]];
NumX:=SequenceToInteger(RandomBinVecX,2);
printf "Random binary vector X:\n %o = %o.\n", RandomBinVecX, NumX;

RandomBinVecY:=[Random(1) : i in [1..k by 1]];
NumY:=SequenceToInteger(RandomBinVecY,2);
printf "Random binary vector Y:\n %o = %o.\n", RandomBinVecY, NumY;

printf "%o + %o = %o.\n", NumX, NumY, NumX+NumY;
Wrk:=IntegerToSequence(NumX+NumY,2);
if Wrk eq [] then Wrk:=[0]; end if;
printf "The results of Bitwise XOR and summation are not the same in general:\n%o = %o.\n%o = %o.\n%o = %o.\n\n", RandomBinVecX, NumX, RandomBinVecY, NumY, Wrk, NumX+NumY;

SumForX:=&+[RandomBinVecX[i]*Weights[i] : i in [1..k by 1]];
SumForY:=&+[RandomBinVecY[i]*Weights[i] : i in [1..k by 1]];

printf "For this reason we will use the sum of weights:\n1) sum of weights for X: %o;\n2) sum of weights for Y: %o.\n", SumForX, SumForY;
printf "The sum of sums: %o + %o = %o.\n", SumForX, SumForY, SumForX+SumForY;

"\n-- Generation of ElGamal keys (do it once in real implementation) --\n";

t:=ClockCycles();
MyKeys:=ElGamalKeys(G,q);
ElGamalKeysCs:=ClockCycles()-t;

MyPublicKey:=MyKeys[1];
MySecretKey:=MyKeys[2];

"Public key:\n",MyPublicKey;
"\nSecret key:\n",MySecretKey;

"\n-- ElGamal encryption of a pair of numbers --\n";

t:=ClockCycles(); 
CipherText1:=ElGamalEncryption(SumForX,MyPublicKey,G,q);
ElGamalEncryption1Cs:=ClockCycles()-t;
printf "Ciphertext (a pair of points) for %o:\n%o\n", SumForX, CipherText1;

t:=ClockCycles(); 
CipherText2:=ElGamalEncryption(SumForY,MyPublicKey,G,q);
ElGamalEncryption2Cs:=ClockCycles()-t;
printf "\nCiphertext (a pair of points) for %o:\n%o\n", SumForY, CipherText2;

"\n-- Summation of a pair of ElGamal ciphertexts --\n";

t:=ClockCycles();
MyCipherText:=[CipherText1[1]+CipherText2[1],CipherText1[2]+CipherText2[2]];
MyCipherTextCs:=ClockCycles()-t;

"Pointwise sum of ciphertexts (a pair of points):\n",MyCipherText;

"\n-- Decryption of the sum of a pair of ElGamal ciphertexts --\n";

t:=ClockCycles();
ResultPoint:=ElGamalDecryption(MyCipherText,MySecretKey);
ElGamalDecryptionCs:=ClockCycles()-t;

"The result of decryption:\n",ResultPoint;

"\n-- MAPPING TO BINARY VECTOR --\n";

t:=ClockCycles();
Solution:=GaudrySchost(ResultPoint,G,(&+Weights)*2);
GetGaudrySchostCs:=ClockCycles()-t;

t:=ClockCycles();
ReconstructedBinVec:=BinVecReconstruction(Solution[1],k);
GetBinVecReconstructionCs:=ClockCycles()-t;

printf "ECDLP solution found by means of Gaudry-Schost algorithm: %o.\n", Solution[1];
printf "Amount of trials in Gaudry-Schost algorithm: %o.\n", Solution[2];
printf "Reconstructed binary vector: \nZ=%o.\n", ReconstructedBinVec;
 
printf "Check bitwise XOR of vectors:\nX=%o\nY=%o\nZ=%o:%o\n", RandomBinVecX, RandomBinVecY, ReconstructedBinVec, BitwiseVectorXOR(RandomBinVecX,RandomBinVecY,k) eq ReconstructedBinVec;

printf "\nTime and clock cycles spent on procedures that are performed once:\n";
printf "1) domain parameters setup: %o sec.\n", DomainParSetUpTime;
printf "2) generation of keys (clock cycles): %o.\n", ElGamalKeysCs;
printf "3) constructing a set of optimal weights (clock cycles): %o.\n", OptimalWeightsCs;

printf "\nClock cycles:\n";
printf "1) 1-st encryption: %o.\n", ElGamalEncryption1Cs;
printf "2) 2-nd encryption: %o.\n", ElGamalEncryption2Cs;
printf "3) summation of a pair of ciphertexts: %o.\n", MyCipherTextCs;
printf "4) decryption: %o.\n", ElGamalDecryptionCs;
printf "5) finding ECDLP solution using Gaudry-Schost algorithm: %o.\n", GetGaudrySchostCs;
printf "6) binary vector reconstruction: %o.\n", GetBinVecReconstructionCs;
printf "7) decryption+Gaudry-Schost+reconstruction: %o.\n", ElGamalDecryptionCs+GetGaudrySchostCs+GetBinVecReconstructionCs;

printf "\nMemory usage in MB (does not include the executable code):\n";
printf "1) current memory usage: %.2o MB.\n", GetMemoryUsage()/10.0^6;

quit;