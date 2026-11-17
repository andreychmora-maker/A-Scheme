# A-Scheme: Information-Theoretic Covert Transport

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.23578925.svg)](https://doi.org/10.5281/zenodo.23578925)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

[![Magma Compatible](https://img.shields.io/badge/Language-Magma%20V2.29--10-blue.svg)](http://magma.maths.usyd.edu.au/)
[![Code Rate](https://img.shields.io/badge/Code%20Rate-R%3D0.75-green.svg)]()

This repository contains the proof-of-concept (PoC) implementation, benchmarking suite, and interactive simulators for the A-Scheme framework, which provides homomorphic XOR emulation and attribute-driven access control.

## Repository Contents

- **`a-scheme-base3-demo.html`**: An interactive web simulator demonstrating the Base-3 Packing technique and homomorphic XOR emulation over the GF(256) field. The simulator visualizes the EC-ElGamal cryptographic layer, blind server-side addition, and client-side scalar extraction with subsequent bitwise reconstruction.
- **`SaaC_prototyping.m`**: The master Magma script implementing the full protocol lifecycle: from Bootstrap and key derivation to secure session establishment and ratcheting (Reinitialization). The script utilizes RFC 5869 HKDF for all chain operations, Elligator Squared for elliptic curve point obfuscation, and a 2-Bit Parity Filter for steganographic metadata concealment.
- **`benchmark.m`**: A script for comprehensive end-to-end benchmarking of the baseline A-Scheme. It integrates a standard Reed-Solomon [255, 128, 128]₂₅₆ algebraic engine over GF(256) (code rate *R* ≈ 0.50), Curve25519 cryptographic primitives, and homomorphic XOR emulation featuring O(1) table-based ECDLP resolution.
- **`rs256_192_65.m`**: An upgraded end-to-end Magma benchmark script implementing the high-rate extended non-systematic Reed-Solomon [256, 192, 65]₂₅₆ algebraic engine over GF(256) (code rate *R* = 0.75). It incorporates a random invertible scrambling matrix *S* ∈ GL(192, GF(256)) for MDS puncturing defense, 256-byte Curve25519 homomorphic XOR evaluation, punctured syndrome decoding (clearing ℵ = 31 symbol errors), and linear payload recovery via submatrix inversion.
- **`monolithic-ascheme-scenarios.m`**: An end-to-end protocol and cryptanalytic attack verification suite over Curve25519. It validates the monolithic KEM payload encapsulation (session keys, integrity hashes, broadcast rosters, salts and compact Schnorr signatures) along with self-unmasking ephemeral half-radius blind noise (wt(<b><i>ξ</i></b><sub><i>i</i></sub>) = 23, <i>w</i><sub>attr</sub> ≤ 8) generated via deterministic `Expand_PRG` expansion. It simulates 7 distinct operational and adversarial scenarios—including an 850,000-pair Monte Carlo simulation—demonstrating complete resilience against cross-session linear addition attacks, tag annihilation failures, and full session compromise.
- **`differing-cohorts.m`**: A standalone Magma script for exact analytical and Monte Carlo evaluation of inter-cohort isolation under Distinct-Sender Cohort Addition attacks (<b>c</b>'<sub><i>A</i></sub> + <b>c</b>'<sub><i>B</i></sub>) at baseline Hamming distance <i>d</i><sub>H</sub>(<b><i>r</i></b><sub><i>A</i></sub>, <b><i>r</i></b><sub><i>B</i></sub>) = 64.
- **`optimized_Gaudry-Schost.m`**: A memory-optimized Magma implementation of the Gaudry-Schost algorithm for resolving the short-interval ECDLP on Montgomery Curve25519 without relying on precomputed lookup tables. The algorithm leverages equivalence classes (coordinates with opposite signs) and an asymmetric compression ratio of 0.1 to accelerate the collision search.

## Security Highlights: Ephemeral Blind Noise & Cross-Session Defense

To prevent advanced inter-frame and cross-session linear addition attacks (<b>c</b>'<sub>1</sub> + <b>c</b>'<sub>2</sub>) by an honest-but-curious server, the A-Scheme integrates stream-seeded ephemeral half-radius blind noise (<b><i>ξ</i></b><sub><i>i</i></sub> with weight <i>w</i><sub><i>ξ</i></sub> = 23, paired with attribute discrepancy budget <i>w</i><sub>attr</sub> ≤ 8 at mutation radius <i>r</i><sub>mut</sub> = 4):

- **Intra-Epoch and Inter-Session Protection:** While static Access Codes allow mask annihilation under pairwise combinations (<i>T</i> = 2), injecting per-session ephemeral blind noise ensures that any attempted linear addition combines independent support weights (wt(<b><i>ξ</i></b><sub><i>a</i></sub> + <b><i>ξ</i></b><sub><i>b</i></sub>) = 2<i>w</i><sub><i>ξ</i></sub> − <i>s</i> − <i>c</i>), yielding a total error weight strictly exceeding both the unique Reed–Solomon decoding threshold (ℵ = 31) and the full-code Guruswami–Sudan Johnson bound (<i>J</i>(255, 192) = 34), with unique-decoding collision probabilities bounded below 1.50 × 10<sup>−12</sup> ≈ 2<sup>−39.3</sup> (and 2.30 × 10<sup>−10</sup> ≈ 2<sup>−32.0</sup> at <i>w</i><sub><i>ξ</i></sub> = 22).
- **Cross-Session Key Isolation:** By binding the ephemeral noise generation to the session key and cryptographic salt (<b><i>ξ</i></b><sub><i>i</i></sub> = Expand<sub>PRG</sub>(<i>κ̂</i><sub><i>i</i></sub> || <i>σ</i><sub><i>i</i></sub>)) or localizing <b><i>ξ</i></b><sub><i>i</i></sub> via CSPRNG in the left-hand blocker coordinates, the server is prevented from decoding the linear payload sum <i>κ</i><sub>1</sub> ⊕ <i>κ</i><sub>2</sub>, preserving full inter-session key isolation even if a historical session key is compromised.

## An Interactive Web Simulator

### Overview
This supplementary material provides an interactive, standalone simulation of the **Base-3 Packing** technique and the homomorphic evaluation process.

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

The complete protocol pipeline and cryptanalytic defense suite—including an **850,000-pair Monte Carlo simulation** at <i>w</i><sub>ξ</sub> = 23, <i>w</i><sub>attr</sub> = 8—execute directly in the **Magma Online Calculator** (`http://magma.maths.usyd.edu.au/calc/`) in **59.710 seconds** (within the 60-second web sandbox limit). Across all 850,000 trials, the empirical mean support overlap converges to **2.075** (matching the theoretical expectation E[<i>s</i>] = 23<sup>2</sup> / 255 ≈ 2.075 to three decimal places), and the minimum observed combined noise weight is **36**, remaining strictly above both the unique Berlekamp–Massey decoding radius (ℵ = 31) and the full-code Guruswami–Sudan Johnson bound (<i>J</i>(255, 192) = 34).

### Console Output (`Magma V2.29`)

```text
=== MONOLITHIC A-SCHEME SETUP ON CURVE25519 (Online Calculator) ===
Generating O(1) ECDLP LUT on Curve25519 for Max Z = 13120...
Domain & Non-Systematic RS Setup completed in 0.200 sec.

=== PART 4: FAST HOMOMORPHIC CHANNEL & DECODER BENCHMARK ([255, 192, 64]_256) ===
[!] Executing Per-Byte Homomorphic EC-ElGamal XOR (256 blocks)...
Homomorphic Pipeline Time (256 independent ElGamal blocks): 2.090 sec.
RS Status: SUCCESS=true (Cleared 31 / 31 errors) | Payload Match: true | Avg Decode: 2802047 CPU Cycles

==========================================================================
PART 5: MONOLITHIC A-SCHEME PROTOCOL & CRYPTANALYTIC ATTACK SCENARIOS
==========================================================================
Provisioned Cohort Users U_1, U_2, U_3 | wt(r_1) = 64 (> 31) | d_H(r_1, r_2) = 8 (<= w_attr = 8)

=== SCENARIO 1: END-TO-END A-SCHEME (Expand_PRG NOISE + ATTRIBUTE RECOVERY & SCHNORR VERIFY) ===
  [Receiver U_2] Blind RS Decode: true | Combined wt(e_attr + xi_1) = 31 (<= aleph = 31)
  [Receiver U_2] Regenerated xi'_1 == xi_1: true | Sender Attributes r'_1 == r_1: true
  [Receiver U_2] Hash Integrity: true | Dealer Schnorr Signature Valid: true | Session Key Match: true

=== SCENARIO 2A: CROSS-SESSION KEY-SUM EXPOSURE WITHOUT BLIND NOISE (xi = 0) ===
  [Without xi_i] Server RS Decode on (c'_1 + c'_2): true (wt = 0)
  [Without xi_i] Linear Payload Sum (kappa_1 + kappa_2) Exposed:    true
  [Without xi_i] Session Key kappa_2 Leaked if Historical kappa_1 Compromised: true

=== SCENARIO 2B: SAME-SENDER CROSS-SESSION ADDITION DEFEATED BY xi_i (wt(xi) = 23) ===
  [With xi_i] Support Overlap |supp(xi_1) cap supp(xi_2)| = 1
  [With xi_i] Combined Blind Noise Weight wt(xi_1 + xi_2) = 45 (> aleph = 31)
  [With xi_i] Server RS Decode on (c'_1 + c'_2): false -> CROSS-SESSION ADDITION BLOCKED!

=== SCENARIO 3: DISTINCT-SENDER ADDITION ATTACK (c'_U1 + c'_U2 IN SAME COHORT) ===
  Attribute Distance wt(r_1 + r_2) = 8 (<= 8), but Total Error wt(r_1 + r_2 + xi_1 + xi_3) = 52 (> 31)
  Server RS Decode on (c'_U1 + c'_U2): false -> ATTRIBUTE DIFFERENCE & KEY EXTRACTION BLOCKED!

=== SCENARIO 4: HOMOMORPHIC ODD COALITION (T = 3) BASE-3 CARRY AVALANCHE ===
  Total 255B RS Core Error Weight (Base-3 Carry Avalanche): 252 / 255 | RS Decode: false

=== SCENARIO 5: EVEN COALITION (T = 2) MASK ANNIHILATION FAILURE ===
  Total 255B RS Core Error Weight (Uncanceled w, m): 251 / 255 | RS Decode: false

=== SCENARIO 6: LEFT-HALF LOCALIZED CSPRNG NOISE (RESILIENCE UNDER FULL kappa_1 LEAK TO SERVER) ===
  [Legitimate U_2] Blind Decode: true (wt = 31) | Direct Right-Half Attribute Recovery (r'_1 == r_1): true
  [Server + Leaked kappa_1] Residual Error on Session 2: wt(xi_loc_2 - xi_loc_1) = 43 (> 31) | Decode: false -> BLOCKED!

=== SCENARIO 7: ANALYTICAL & 850000-PAIR MONTE CARLO SUPPORT OVERLAP BOUND ===
  [Profile wt(xi)=20, w_attr<=11] Exact Pr[s >= 9]  = 1.635924364E-6 | Total Pr[wt <= 31] = 2.382234622E-6 (~ 2^-18.7)
  [Profile wt(xi)=22, w_attr<=9]  Exact Pr[s >= 13] = 7.912538399E-11 | Total Pr[wt <= 31] = 2.298592658E-10 (~ 2^-32.0)
  [Profile wt(xi)=23, w_attr<=8]  Exact Pr[s >= 15] = 2.950130609E-13 | Total Pr[wt <= 31] = 1.504660580E-12 (~ 2^-39.3)
  Theoretical E[s] = 2.075 | Empirical Mean Overlap (850000 pairs) = 2.075
  Empirical Minimum wt(xi_a + xi_b) across 850000 pairs: 36 (Threshold aleph = 31, Johnson J = 34) | Collisions: 0

=== ALL PROTOCOL STAGES & ATTACK SCENARIOS COMPLETED IN 59.710 SEC ===
```

### Verification Summary Table

| Scenario | Operational / Adversarial Test Case | Observed Weight `wt(e)` | Bound (ℵ = 31, <i>J</i> = 34) | RS Decode | Security Verdict |
| :--- | :--- | :---: | :---: | :---: | :--- |
| **Sc. 1** | End-to-End Monolithic KEM + `Expand_PRG` Stripping & Schnorr Verify | `31` (`8 + 23`) | `<= 31` | `true` | ✅ Validated (<b><i>r</i></b>'<sub>1</sub> = <b><i>r</i></b><sub>1</sub>) |
| **Sc. 2A** | Cross-Session Addition without Blind Noise (<b><i>ξ</i></b><sub><i>i</i></sub> = <b>0</b> Baseline) | `0` | `<= 31` | `true` | ⚠️ <i>κ</i><sub>1</sub> + <i>κ</i><sub>2</sub> Exposed |
| **Sc. 2B** | Same-Sender Cross-Session Addition (<b>c</b>'<sub>1</sub> + <b>c</b>'<sub>2</sub>) with wt(<b><i>ξ</i></b><sub><i>i</i></sub>) = 23 | `45` (`overlap = 1`) | `> 34 > 31` | `false` | 🛡️ Addition Blocked |
| **Sc. 3** | Distinct-Sender Cohort Addition (<b>c</b>'<sub>U<sub>1</sub></sub> + <b>c</b>'<sub>U<sub>2</sub></sub>, <i>d</i><sub>H</sub>(<b><i>r</i></b><sub>1</sub>,<b><i>r</i></b><sub>2</sub>) = 8) | `52` | `> 34 > 31` | `false` | 🛡️ Attribute Diff Blocked |
| **Sc. 4** | Homomorphic Odd Coalition (T = 3, 4 Operands in `G`) | `252 / 255` | `> 34 > 31` | `false` | 🛡️ Base-3 Carry Avalanche |
| **Sc. 5** | Homomorphic Even Coalition (T = 2, <b>M</b><sub>U<sub>2</sub></sub> + <b>M</b><sub>U<sub>3</sub></sub> Self-Annihilation) | `251 / 255` | `> 34 > 31` | `false` | 🛡️ Masks (<b>w</b>, <b>m</b>) Intact |
| **Sc. 6** | Left-Half Localized CSPRNG Noise under Full <i>κ</i><sub>1</sub> Leak to Server | `31` (U<sub>2</sub>) / `43` (Srv) | `<= 31` / `> 34` | `true` / `false` | 🛡️ Session 2 Protected |
| **Sc. 7** | Analytical Hypergeometric Bound & `850,000`-Pair Monte Carlo (w<b><sub><i>ξ</i></b></sub> = 23) | `min = 36` (`E[s] = 2.075`) | `> 34 > 31` | `0 collisions` | ✅ Pr ≈ 1.50e-12 (~2<sup>-39.3</sup>) |

### Analytical & Empirical Distribution of Combined Blind Noise (wt(<b><i>ξ</i></b><sub><i>a</i></sub> + <b><i>ξ</i></b><sub><i>b</i></sub>))

![Cross-Session Blind Noise Overlap & Probability Distribution](./blind_noise_overlap_chart.png)

When an adversary or honest-but-curious Server sums two perturbed frames <b>c</b>'<sub><i>a</i></sub> + <b>c</b>'<sub><i>b</i></sub> from the same sender, the static masks (<b>w</b>, <b>m</b>) cancel in characteristic 2, leaving the sum of two independent ephemeral blind noise vectors <b><i>ξ</i></b><sub><i>a</i></sub> + <b><i>ξ</i></b><sub><i>b</i></sub> of individual weight <i>w</i><sub><i>ξ</i></sub> over the <i>N</i> = 255 cyclic Reed–Solomon core coordinates. If their supports overlap in <i>s</i> = |supp(<b><i>ξ</i></b><sub><i>a</i></sub>) ∩ supp(<b><i>ξ</i></b><sub><i>b</i></sub>)| coordinates (following a hypergeometric distribution with expectation E[<i>s</i>] = <i>w</i><sub><i>ξ</i></sub><sup>2</sup> / 255) and c ~ Bin(s, 1/255) overlapping coordinates randomly cancel to zero in GF(256)* = GF(256) \ {0}, the resulting combined error weight is:

<p align="center">wt(<b><i>ξ</i></b><sub><i>a</i></sub> + <b><i>ξ</i></b><sub><i>b</i></sub>) = 2<i>w</i><sub><i>ξ</i></sub> − <i>s</i> − <i>c</i>.</p>

The two-panel chart above illustrates the exact analytical and empirical security margins across parameter profiles (<i>w</i><sub><i>ξ</i></sub>, <i>w</i><sub>attr</sub>) satisfying <i>w</i><sub><i>ξ</i></sub> + <i>w</i><sub>attr</sub> = ℵ = 31:

1. **Left Panel — Super-Exponential Growth of Cross-Session Collision Security (−log<sub>2</sub> Pr[wt ≤ <i>t</i>]):**
   - Each `+1` byte increment in <i>w</i><sub><i>ξ</i></sub> raises the baseline uncancelled sum 2<i>w</i><sub><i>ξ</i></sub> by `+2` symbols, increasing the required cancellation threshold <i>s</i> + <i>c</i> ≥ 2<i>w</i><sub><i>ξ</i></sub> − <i>t</i> by `2` and adding **≈ 6.5–7.5 bits** of statistical collision resistance.
   - **Blue Curve (Unique Decoding Radius ℵ = 31):** Tracks the exact probability that wt(<b><i>ξ</i></b><sub><i>a</i></sub> + <b><i>ξ</i></b><sub><i>b</i></sub>) ≤ 31 (resolvable via Berlekamp–Massey decoding). Security scales from **18.7 bits** (Pr ≈ 2.38 × 10<sup>−6</sup> at <i>w</i><sub><i>ξ</i></sub> = 20) to **32.0 bits** (Pr ≈ 2.30 × 10<sup>−10</sup> at <i>w</i><sub><i>ξ</i></sub> = 22) and reaches **39.3 bits** (Pr ≈ 1.50 × 10<sup>−12</sup>) at the optimal profile **<i>w</i><sub><i>ξ</i></sub> = 23, <i>w</i><sub>attr</sub> ≤ 8**.
   - **Red Dashed Curve (Full-Code Guruswami–Sudan Johnson Bound <i>J</i>(255, 192) = ⌊255 − √(255 · 191)⌋ = 34):** Tracks the probability that wt(<b><i>ξ</i></b><sub><i>a</i></sub> + <b><i>ξ</i></b><sub><i>b</i></sub>) ≤ 34. Under constructive cohort provisioning with mutation radius <i>r</i><sub>mut</sub> = 4, the maximum pairwise attribute distance is an even integer <i>d</i><sub>H</sub>(<b>r</b><sub><i>i</i></sub>, <b>r</b><sub><i>j</i></sub>) ≤ 4 + 4 = 8. Reallocating the unused 9th byte from <i>w</i><sub>attr</sub> = 9 → 8 to <i>w</i><sub><i>ξ</i></sub> = 22 → 23 preserves the full cohort capacity (> C(128, 4) · 255<sup>4</sup> ≈ 4.51 × 10<sup>16</sup> ≈ 2<sup>55.3</sup> profiles) while boosting Johnson-bound security by **+6.2 bits** (73× reduction in tail probability, from 2<sup>−19.5</sup> to **2<sup>−25.7</sup>**).

2. **Right Panel — Probability Mass Function (PMF) of wt(<b><i>ξ</i></b><sub><i>a</i></sub> + <b><i>ξ</i></b><sub><i>b</i></sub>) vs. Decoding Thresholds:**
   - Plots the exact logarithmic probability distribution Pr[wt(<b><i>ξ</i></b><sub><i>a</i></sub> + <b><i>ξ</i></b><sub><i>b</i></sub>) = <i>w</i>] for <i>w</i><sub><i>ξ</i></sub> ∈ {20, 22, 23} against the **Unique Decoding Radius (ℵ = 31, solid blue line)** and the **Johnson Bound (<i>J</i> = 34, dashed red line)**.
   - At <i>w</i><sub><i>ξ</i></sub> = 22 (orange curve), the probability at <i>w</i> = 34 is ≈ 1.25 × 10<sup>−6</sup> (≈ 1 in 800,000 pairs), explaining why ultra-large simulations of ~8 × 10<sup>5</sup> trials can touch the asymptotic Johnson boundary <i>J</i> = 34.
   - At **<i>w</i><sub><i>ξ</i></sub> = 23 (green curve)**, increasing the individual noise weight from 22 to 23 raises the disjoint baseline weight to 2<i>w</i><sub><i>ξ</i></sub> = 46, shifting the entire distribution right by `+2` symbols. Because two random 23-element supports over <i>N</i> = 255 coordinates overlap on average in E[<i>s</i>] = 23<sup>2</sup> / 255 ≈ 2.075 positions (most commonly <i>s</i> ∈ {1, 2, 3}) and rarely cancel to zero in GF(256)* (<i>c</i> ≈ 0), over 77% of the probability mass concentrates tightly around the peak weights <i>w</i> = 46 − <i>s</i> ∈ {43, 44, 45}. This rightward shift pulls the left tail of the distribution away from the decoding danger zones: across **850,000 Monte Carlo pair trials** in Magma, the worst-case empirical minimum combined weight is **wt = 36 (dotted green vertical line)**—remaining strictly above both the Guruswami–Sudan Johnson bound (<i>J</i> = 34) and the Berlekamp–Massey unique decoding threshold (ℵ = 31) with **0 decodable collisions**.

#### Why 39.3 Bits of Statistical Blind-Noise Margin Equals Full Cryptographic Security

A standalone statistical figure of **39.3 bits** (Pr ≈ 1.50 × 10<sup>−12</sup>) might appear modest if mistaken for an offline brute-force key space. In the A-Scheme, however, 39.3 bits is **not** a key length—it is an **online, per-pair statistical dampening factor** that operates on top of multiple independent cryptographic and algebraic barriers:

1. **Primary Cryptographic Layer (~128-Bit Curve25519 ECDLP):** External adversaries cannot add or inspect frames in GF(256) at all; every byte is packed in Base-3 and encrypted under Curve25519 EC-ElGamal (~128-bit security). The blind-noise overlap bound only applies to an **honest-but-curious Server** that holds the homomorphic evaluation capability *and* has simultaneously compromised a historical session key <i>κ</i><sub>1</sub> (without a leaked key, even a decoded payload sum <i>κ</i><sub>1</sub> ⊕ <i>κ</i><sub>2</sub> retains **256 bits** of information-theoretic entropy).
2. **No Offline Brute Force (Online Frame-Rate Bottleneck):** Because <b><i>ξ</i></b><sub><i>i</i></sub> = Expand<sub>PRG</sub>(<i>κ̂</i><sub><i>i</i></sub> || <i>σ</i><sub><i>i</i></sub>) is cryptographically bound to authenticated session frames, an attacker cannot locally grind noise vectors on a GPU. Nor can the Server apply a birthday attack across arbitrary pairs, since summing two *unknown* session keys (<i>κ</i><sub><i>a</i></sub> ⊕ <i>κ</i><sub><i>b</i></sub>) yields no actionable key material. To exploit a single leaked key <i>κ</i><sub>1</sub>, the Server must pair that specific target frame <b>c</b>'<sub>1</sub> against new incoming frames <b>c</b>'<sub><i>j</i></sub> from the **exact same sender within the same epoch**:
   <p align="center"><b>Expected Frames Required</b> = 2<sup>39.27</sup> ≈ 6.60 × 10<sup>11</sup> frames from a single user.</p>
   Even if a client transmitted 100 frames/second continuously, accumulating 2<sup>39.3</sup> frames would take <b> >200 years</b> without ratcheting. Over a realistic epoch lifetime of <i>M</i> = 2<sup>16</sup> (65,536) frames before Reinitialization, the cumulative probability of <b>any</b> decodable collision against a compromised session is:
   <p align="center">Pr<sub>epoch</sub> = 1 − (1 − 2<sup>−39.27</sup>)<sup>65536</sup> ≈ 2<sup>−23.3</sup> ≈ 9.8 × 10<sup>−8</sup> (&lt; 0.00001%).</p>
3. **Scrambling Matrix Defense Against List Decoding (> 128 Bits):** While the raw Guruswami–Sudan Johnson bound (<i>J</i> = 34) sits at 25.7 bits of statistical overlap, algebraic list decoding requires knowledge of the underlying Reed–Solomon parity-check basis. Because the codeword is multiplied by a secret invertible scrambling matrix <b>S</b> ∈ GL(192, GF(256)), the Server cannot execute syndrome or list decoding even if wt(<b><i>ξ</i></b><sub><i>a</i></sub> + <b><i>ξ</i></b><sub><i>b</i></sub>) ≤ 34.
4. **Additive Attribute Distance Across Distinct Senders:** The 39.3-bit bound represents the worst-case **same-sender** scenario (<i>d</i><sub>H</sub>(<b><i>r</i></b><sub>1</sub>, <b><i>r</i></b><sub>1</sub>) = 0). For distinct senders within the same cohort (<i>d</i><sub>H</sub>(<b><i>r</i></b><sub>1</sub>, <b><i>r</i></b><sub>2</sub>) = 8), the baseline error shifts by +8 symbols, raising collision resistance to **> 85 bits** (and scaling even further across differing cohorts, as analyzed in the next section).

| Defense Layer / Threat Context | Mathematical Mechanism | Effective Security Contribution |
| :--- | :--- | :---: |
| **External Eavesdropper** | Curve25519 EC-ElGamal + Elligator Squared | **~128 bits** (Computational) |
| **Server without Leaked Key** | One-Time Pad Masking of <i>κ</i><sub>1</sub> ⊕ <i>κ</i><sub>2</sub> | **256 bits** (Info-Theoretic) |
| **Server + 1 Leaked Key (Same Sender, Per Pair)** | Hypergeometric–Binomial Overlap (<i>w</i><sub>ξ</sub> = 23, wt ≤ 31) | **39.3 bits** (`6.6e11` online frames) |
| **Server + 1 Leaked Key (Per 2<sup>16</sup>-Frame Epoch)** | Epoch Ratcheting Bound: 1 − (1 − 2<sup>−39.3</sup>)<sup>65536</sup> | **Pr<sub>fail</sub> ≈ 2<sup>−23.3</sup>** (`< 10^-7` per epoch) |
| **Distinct Senders (Same Cohort, <i>d</i><sub>H</sub> = 8)** | Attribute Distance + Dual Blind Noise (`wt ≤ 31`) | **> 85 bits** (Statistical) |


### Security of The A-Scheme under Differing Cohorts with ξ-Entropy (`differing-cohorts.m`, <i>d</i><sub>H</sub>(<b><i>r</i></b><sub>A</sub>,<b><i>r</i></b><sub>B</sub>) = 64)

![A-Scheme Security under Differing Cohorts with ξ-Entropy](./covert_diff_cohort_overlap_chart.png)

When an adversary tries to perform a Distinct-Sender Cohort Addition attack (<b>c</b>'<sub><i>A</i></sub> + <b>c</b>'<sub><i>B</i></sub>) where all masks and parameter heuristics align, but the senders belong to entirely differing cohorts, the system benefits from an insurmountable hamming barrier. Because the attribute profiles of users in different cohorts are highly diverse, their distance baseline is <i>d</i><sub>H</sub>(<b><i>r</i></b><sub><i>A</i></sub>,<b><i>r</i></b><sub><i>B</i></sub>) = 64 symbols (each symbol is 1 byte in GF(256)). 

Even if masks and salts are fully aligned, adding these frames yields a total error of E<sub>total</sub> = <i>d</i><sub>H</sub>(<b><i>r</i></b><sub><i>A</i></sub>,<b><i>r</i></b><sub><i>B</i></sub>) + <b><i>ξ</i></b><sub><i>a</i></sub> + <b><i>ξ</i></b><sub><i>b</i></sub>. The standalone script **`differing-cohorts.m`** executes the exact analytical hypergeometric-binomial convolution across <i>w</i><sub>ξ</sub> ∈ {18..25} and a **500,000-pair Monte Carlo verification** in Magma in **57.0 seconds** (within the 60-second web sandbox limit):

```text
=== DIFFERING COHORTS ANALYSIS (d_H(r_A, r_B) = 64, N = 255) ===
  [Profile wt(xi)=18, w_attr<=13] Exact E[wt(E_total)] = 89.98 | Exact Pr[wt <= 34] = 1.882E-92
  [Profile wt(xi)=19, w_attr<=12] Exact E[wt(E_total)] = 91.36 | Exact Pr[wt <= 34] = 1.279E-92
  [Profile wt(xi)=20, w_attr<=11] Exact E[wt(E_total)] = 92.74 | Exact Pr[wt <= 34] = 5.807E-93
  [Profile wt(xi)=21, w_attr<=10] Exact E[wt(E_total)] = 94.12 | Exact Pr[wt <= 34] = 1.920E-93
  [Profile wt(xi)=22, w_attr<= 9] Exact E[wt(E_total)] = 95.48 | Exact Pr[wt <= 34] = 4.892E-94
  [Profile wt(xi)=23, w_attr<= 8] Exact E[wt(E_total)] = 96.85 | Exact Pr[wt <= 34] = 9.993E-95
  [Profile wt(xi)=24, w_attr<= 7] Exact E[wt(E_total)] = 98.21 | Exact Pr[wt <= 34] = 1.686E-95
  [Profile wt(xi)=25, w_attr<= 6] Exact E[wt(E_total)] = 99.56 | Exact Pr[wt <= 34] = 2.400E-96
  [Monte Carlo 500000 pairs, w_xi=23] Empirical Mean = 96.84 | Empirical Min = 82 (> J = 34) | Collisions: 0
```

The analytical and empirical evaluation demonstrates:

1. **Left Panel — Massive Error Weight Scale & Safety Margin:**
   - Instead of falling back near the unique decoding limit, the resulting weight strictly sits in the range of 76 to 100 symbols—well above any possible decoding capability.
   - For the optimal profile <i>w</i><sub><i>ξ</i></sub> = 23, the exact analytical expected weight is **96.85 bytes** (empirical mean **96.84 bytes** across 500,000 trials), with the worst-case empirical minimum observed at **82 bytes**. This creates a massive safety buffer of **48 bytes** beyond the list-decoding Johnson bound (<i>J</i> = 34) and **51 bytes** beyond the unique decoding threshold (ℵ = 31).

2. **Right Panel — Isolated Probability Density (PMF) & >312-Bit Security:**
   - Plots the probability mass function for <i>w</i><sub><i>ξ</i></sub> ∈ {20, 22, 23} at baseline cohort distance <i>d</i><sub>H</sub> = 64.
   - The error weight distribution forms tight Gaussian-like curves centered between 90 and 100.
   - Reducing the combined weight from 64 down to <i>J</i> = 34 requires the sum <b><i>ξ</i></b><sub><i>a</i></sub> + <b><i>ξ</i></b><sub><i>b</i></sub> to land inside the 64-byte support of Δ<b><i>r</i></b><sub><i>AB</i></sub> and randomly match its exact byte values in GF(256)* across at least 30 coordinates simultaneously. At <i>w</i><sub><i>ξ</i></sub> = 23, the exact analytical probability of falling at or below the Johnson bound (wt ≤ 34) is **9.993 × 10<sup>−95</sup> ≈ 2<sup>−312.3</sup>** (over **312 bits** of security), with **0 collisions** across all 500,000 trials.

## 📚 Academic Citation

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
  url          = {[https://doi.org/10.5281/zenodo.23574958](https://doi.org/10.5281/zenodo.23574958)}
}
```
