# A-Scheme: Information-Theoretic Covert Transport

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.23578925.svg)](https://doi.org/10.5281/zenodo.23578925)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

[![Magma Compatible](https://img.shields.io/badge/Language-Magma%20V2.29--10-blue.svg)](http://magma.maths.usyd.edu.au/)
[![Code Rate](https://img.shields.io/badge/Code%20Rate-R%3D0.75-green.svg)]()

This repository contains the proof-of-concept (PoC) implementation, benchmarking suite, and interactive simulators for the A-Scheme framework, which provides homomorphic XOR emulation and attribute-driven access control.

## Repository Contents

- **`a-scheme-base3-demo.html`**: An interactive web simulator demonstrating the Base-3 Packing technique and homomorphic XOR emulation over the GF(256) field. The simulator visualizes the EC-ElGamal cryptographic layer, blind server-side addition, and client-side scalar extraction with subsequent bitwise reconstruction.
- **`SaaC_prototyping.m`**: The master Magma script implementing the full protocol lifecycle: from Bootstrap and key derivation to secure session establishment and ratcheting (Reinitialization). The script utilizes RFC 5869 HKDF for all chain operations, Elligator Squared for elliptic curve point obfuscation, and a 2-Bit Parity Filter for steganographic metadata concealment.
- **`benchmark_.m`**: A script for comprehensive end-to-end benchmarking of the baseline A-Scheme. It integrates a standard Reed-Solomon [255, 128, 128]₂₅₆ algebraic engine over GF(256) (code rate *R* ≈ 0.50), Curve25519 cryptographic primitives, and homomorphic XOR emulation featuring O(1) table-based ECDLP resolution.
- **`rs256_192_65.m`**: An upgraded end-to-end Magma benchmark script implementing the high-rate extended non-systematic Reed-Solomon [256, 192, 65]₂₅₆ algebraic engine over GF(256) (code rate *R* = 0.75). It incorporates a random invertible scrambling matrix *S* ∈ GL(192, GF(256)) for MDS puncturing defense, 256-byte Curve25519 homomorphic XOR evaluation, punctured syndrome decoding (clearing aleph = 31 symbol errors), and linear payload recovery via submatrix inversion.
- **`monolithic-ascheme-scenarios.m`**: An end-to-end protocol and cryptanalytic attack verification suite over Curve25519. It validates the monolithic KEM payload encapsulation (session keys, integrity hashes, broadcast rosters, and compact Schnorr signatures) along with self-unmasking ephemeral half-radius blind noise ($wt(\mathbf{\xi}) = 22$) generated via deterministic Expand_PRG expansion. It simulates 7 distinct operational and adversarial scenarios, demonstrating complete resilience against cross-session linear addition attacks, tag annihilation failures, and full session compromise.
- **`optimized_Gaudry-Schost.m`**: A memory-optimized Magma implementation of the Gaudry-Schost algorithm for resolving the short-interval ECDLP on Montgomery Curve25519 without relying on precomputed lookup tables. The algorithm leverages equivalence classes (coordinates with opposite signs) and an asymmetric compression ratio of 0.1 to accelerate the collision search.

## Security Highlights: Ephemeral Blind Noise & Cross-Session Defense

To prevent advanced inter-frame and cross-session linear addition attacks ($\mathbf{c}'_1 + \mathbf{c}'_2$) by an honest-but-curious server, the A-Scheme integrates stream-seeded ephemeral half-radius blind noise ($\mathbf{\xi}_i$ with weight 22):

- **Intra-Epoch and Inter-Session Protection:** While static static Access Codes allow mask annihilation under pairwise combinations ($T = 2$), injecting per-session ephemeral blind noise ensures that any attempted linear addition combines independent support weights, yielding a total error weight far exceeding the Reed-Solomon decoding threshold ($\aleph=31$), with collision probabilities bounded below $2^{-32.0}$.
- **Sender Unlinkability:** By binding the ephemeral noise generation to the session key and cryptographic salt (ξ_i = Expand_PRG(κ̂ || σ_i)), static salt and signature fields are prevented from vanishing during server-side summations, completely preserving sender unlinkability across transactions.

## An Interactive Web Simulator

### Overview
This supplementary material provides an interactive, standalone simulation of the **Base-3 Packing** technique and the homomorphic evaluation process introduced in the paper: *"Scalable Attribute-Based Encryption in Hamming Metric via Packed Additive Homomorphism"*.

The simulator allows users to visually and mathematically explore how bitwise XOR operations are emulated within additively homomorphic scalar rings without carry-over, and how the underlying EC-ElGamal randomizers are algebraically annihilated during decryption.

### Technical Note: The Byte-to-Scalar Pipeline
This interactive widget simulates the exact processing of a single attribute (an 8-bit byte) from the access vectors over GF(256). The homomorphic XOR emulation transitions smoothly between three mathematical domains:

1. **Deconstruction (Finite Field):** An individual attribute from the access vector is strictly mapped to an 8-bit binary representation (*x*, *y* ∈ {0, 1}⁸).
2. **Base-3 Packing (Scalar Ring):** These 8 bits are weighted and packed into a single carry-free scalar value (*η* = 8, maximum scalar sum = 6560).
3. **Cryptographic Layer (Elliptic Curve):** The server homomorphically adds these packed scalars across ciphertexts using standard EC point addition. The simulation details the EC-ElGamal layer, illustrating how random ephemeral scalars mask the points and how these masks are subsequently annihilated by the receiver's private key.
4. **Unpacking (Arithmetic):** The receiver resolves the short-interval ECDLP via the Gaudry-Schost algorithm to recover the sum, then iteratively extracts the exact XORed bits via modulo-3 and modulo-2 arithmetic.
5. **Reassembly (Finite Field):** The reconstructed bits are assembled back into the exact bitwise XOR difference (denoted as *e* ∈ GF(256)), successfully demonstrating a carry-free XOR operation over the original inputs.

### System Requirements
- **Dependencies:** None. The demonstration relies entirely on standard vanilla HTML, CSS, and JavaScript.
- **Network:** No internet connection is required to run the simulation after downloading.
- **Compatibility:** Works on any modern web browser (Google Chrome, Mozilla Firefox, Apple Safari, Microsoft Edge, etc.).

### How to Run the Demonstration
1. Download the `a-scheme-base3-demo.html` file to your local machine.
2. Double-click the downloaded `.html` file. It will automatically open in your default web browser.
3. Use the interactive buttons to toggle the individual bits of the Sender's and Receiver's attributes.
4. Click the **"Evaluate Homomorphic Crypto Pipeline ↓"** button to step through the Server-Side blind addition, the Client-Side mask annihilation, and the Base-3 extraction math.
5. Click the **"↻ Generate New Random Attributes & Restart"** button at the bottom to quickly test the mathematical consistency against different random bit combinations.

### Security & Privacy Note
This is a purely client-side simulation. No data is transmitted, and no external libraries or APIs are called.
## Empirical Verification & Cryptanalytic Benchmark (`monolithic-ascheme-scenarios.m`)

The complete protocol pipeline and cryptanalytic defense suite execute directly in the **Magma Online Calculator** (`http://magma.maths.usyd.edu.au/calc/`) in **16.870 seconds** (well within the 60-second sandbox limit).

### Console Output (`Magma V2.29`)

```text
=== MONOLITHIC A-SCHEME SETUP ON CURVE25519 (Online Calculator) ===
Generating O(1) ECDLP LUT on Curve25519 for Max Z = 13120...
Domain & Non-Systematic RS Setup completed in 0.190 sec.

=== PART 4: FAST HOMOMORPHIC CHANNEL & DECODER BENCHMARK ([255, 192, 64]_256) ===
[!] Executing Per-Byte Homomorphic EC-ElGamal XOR (256 blocks)...
Homomorphic Pipeline Time (256 independent ElGamal blocks): 2.090 sec.
RS Status: SUCCESS=true (Cleared 31 / 31 errors) | Payload Match: true | Avg Decode: 2768273 CPU Cycles

==========================================================================
PART 5: MONOLITHIC A-SCHEME PROTOCOL & CRYPTANALYTIC ATTACK SCENARIOS
==========================================================================
Provisioned Cohort Users U_1, U_2, U_3 | wt(r_1) = 62 (> 31) | d_H(r_1, r_2) = 8 (<= w_attr = 9)

=== SCENARIO 1: END-TO-END A-SCHEME (Expand_PRG NOISE + ATTRIBUTE RECOVERY & SCHNORR VERIFY) ===
  [Receiver U_2] Blind RS Decode: true | Combined wt(e_attr + xi_1) = 30 (<= aleph = 31)
  [Receiver U_2] Regenerated xi'_1 == xi_1: true | Sender Attributes r'_1 == r_1: true
  [Receiver U_2] Hash Integrity: true | Dealer Schnorr Signature Valid: true | Session Key Match: true

=== SCENARIO 2A: CROSS-SESSION KEY-SUM EXPOSURE WITHOUT BLIND NOISE (xi = 0) ===
  [Without xi_i] Server RS Decode on (c'_1 + c'_2): true (wt = 0)
  [Without xi_i] Linear Payload Sum (kappa_1 + kappa_2) Exposed:    true
  [Without xi_i] Session Key khat_2 Leaked if Historical kappa_1 Compromised: true

=== SCENARIO 2B: SAME-SENDER CROSS-SESSION ADDITION DEFEATED BY xi_i (wt(xi) = 22) ===
  [With xi_i] Support Overlap |supp(xi_1) cap supp(xi_2)| = 3
  [With xi_i] Combined Blind Noise Weight wt(xi_1 + xi_2) = 41 (> aleph = 31)
  [With xi_i] Server RS Decode on (c'_1 + c'_2): false -> CROSS-SESSION ADDITION BLOCKED!

=== SCENARIO 3: DISTINCT-SENDER ADDITION ATTACK (c'_U1 + c'_U2 IN SAME COHORT) ===
  Attribute Distance wt(r_1 + r_2) = 8 (<= 9), but Total Error wt(r_1 + r_2 + xi_1 + xi_3) = 51 (> 31)
  Server RS Decode on (c'_U1 + c'_U2): false -> ATTRIBUTE DIFFERENCE & KEY EXTRACTION BLOCKED!

=== SCENARIO 4: HOMOMORPHIC ODD COALITION (T = 3) BASE-3 CARRY AVALANCHE ===
  Total 255B RS Core Error Weight (Base-3 Carry Avalanche): 253 / 255 | RS Decode: false

=== SCENARIO 5: EVEN COALITION (T = 2) MASK ANNIHILATION FAILURE ===
  Total 255B RS Core Error Weight (Uncanceled w, m): 253 / 255 | RS Decode: false

=== SCENARIO 6: LEFT-HALF LOCALIZED CSPRNG NOISE (RESILIENCE UNDER FULL kappa_1 LEAK TO SERVER) ===
  [Legitimate U_2] Blind Decode: true (wt = 30) | Direct Right-Half Attribute Recovery (r'_1 == r_1): true
  [Server + Leaked kappa_1] Residual Error on Session 2: wt(xi_loc_2 - xi_loc_1) = 41 (> 31) | Decode: false -> BLOCKED!

=== SCENARIO 7: ANALYTICAL & 50,000-PAIR MONTE CARLO SUPPORT OVERLAP BOUND ===
  [Profile wt(xi)=20, w_attr<=11] Exact Pr[s >= 9]  = 1.635924364E-6 | Total Pr[wt <= 31] = 2.382234622E-6 (~ 2^-18.7)
  [Profile wt(xi)=22, w_attr<=9]  Exact Pr[s >= 13] = 7.912538399E-11 | Total Pr[wt <= 31] = 2.298592658E-10 (~ 2^-32.0)
  Theoretical E[s] = 1.898 | Empirical Mean Overlap (50000 pairs) = 1.894
  Empirical Minimum wt(xi_a + xi_b) across 50000 pairs: 36 (Threshold aleph = 31) | Collisions: 0

=== ALL PROTOCOL STAGES & ATTACK SCENARIOS COMPLETED IN 16.870 SEC ===
```

### Verification Summary Table

| Scenario | Operational / Adversarial Test Case | Observed Weight `wt(e)` | Threshold `ℵ` | RS Decode | Security Verdict |
| :--- | :--- | :---: | :---: | :---: | :--- |
| **Sc. 1** | End-to-End Monolithic KEM + `Expand_PRG` Stripping & Schnorr Verify | `30` (`8 + 22`) | `<= 31` | `true` | ✅ Validated (`r'_1 == r_1`) |
| **Sc. 2A** | Cross-Session Addition without Blind Noise (`xi_i = 0` Baseline) | `0` | `<= 31` | `true` | ⚠️ `kappa_1 + kappa_2` Exposed |
| **Sc. 2B** | Same-Sender Cross-Session Addition (`c'_1 + c'_2`) with `wt(xi_i) = 22` | `41` (`overlap = 3`) | `> 31` | `false` | 🛡️ Addition Blocked |
| **Sc. 3** | Distinct-Sender Cohort Addition (`c'_U1 + c'_U2`, `d_H(r_1, r_2) = 8`) | `51` | `> 31` | `false` | 🛡️ Attribute Diff Blocked |
| **Sc. 4** | Homomorphic Odd Coalition (`T = 3`, 4 Operands in `G`) | `253 / 255` | `> 31` | `false` | 🛡️ Base-3 Carry Avalanche |
| **Sc. 5** | Homomorphic Even Coalition (`T = 2`, `M_U2 + M_U3` Self-Annihilation) | `253 / 255` | `> 31` | `false` | 🛡️ Masks `(w, m)` Intact |
| **Sc. 6** | Left-Half Localized CSPRNG Noise under Full `kappa_1` Leak to Server | `30` (U2) / `41` (Srv) | `<= 31` / `> 31` | `true` / `false` | 🛡️ Session 2 Protected |
| **Sc. 7** | Analytical Hypergeometric Bound & `50,000`-Pair Monte Carlo (`w_xi = 22`) | `min = 36` (`E[s] = 1.894`) | `> 31` | `0 collisions` | ✅ `Pr ≈ 2.30e-10 (~2^-32.0)` |

### 📚 Academic Citation

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.23574958.svg)](https://doi.org/10.5281/zenodo.23574958)

If you utilize these scripts in your research, please cite the associated archive:

```bibtex
@misc{chmora2026ascheme,
  author       = {Andrey Chmora},
  title        = {The A-Scheme for Information-Theoretic Covert Transport},
  month        = oct,
  year         = {2026},
  publisher    = {Zenodo},
  doi          = {10.5281/zenodo.23574958},
  url          = {https://doi.org/10.5281/zenodo.23574958}
}
```
