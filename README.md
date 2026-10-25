# A-Scheme: Information-Theoretic Covert Transport

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.23578925.svg)](https://doi.org/10.5281/zenodo.23578925)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

This repository contains the proof-of-concept (PoC) implementation, benchmarking suite, and interactive simulators for the A-Scheme framework, which provides homomorphic XOR emulation and attribute-driven access control.

## Repository Contents

* **`a-scheme-base3-demo.html`**: An interactive web simulator demonstrating the Base-3 Packing technique and homomorphic XOR emulation over the GF(256) field. The simulator visualizes the EC-ElGamal cryptographic layer, blind server-side addition, and client-side scalar extraction with subsequent bitwise reconstruction.
* **`SaaC_prototyping.m`**: The master Magma script implementing the full protocol lifecycle: from Bootstrap and key derivation to secure session establishment and ratcheting (Reinitialization). The script utilizes RFC 5869 HKDF for all chain operations, Elligator Squared for elliptic curve point obfuscation, and a 2-Bit Parity Filter for steganographic metadata concealment.
* **`benchmark_.m`**: A script for comprehensive end-to-end benchmarking of the A-Scheme. It integrates a Reed-Solomon [255, 128, 128] algebraic engine over GF(256), Curve25519 cryptographic primitives, and homomorphic XOR emulation featuring O(1) table-based ECDLP resolution.
* **`optimized_Gaudry-Schost.m`**: A memory-optimized Magma implementation of the Gaudry-Schost algorithm for resolving the short-interval ECDLP on Montgomery Curve25519 without relying on precomputed lookup tables. The algorithm leverages equivalence classes (coordinates with opposite signs) and an asymmetric compression ratio of 0.1 to accelerate the collision search.

## An interactive web simulator

### Overview
This supplementary material provides an interactive, standalone simulation of the **Base-3 Packing** technique and the homomorphic evaluation process introduced in the paper: *"Scalable Attribute-Based Encryption in Hamming Metric via Packed Additive Homomorphism"*.

The simulator allows users to visually and mathematically explore how bitwise XOR operations are emulated within additively homomorphic scalar rings without carry-over, and how the underlying EC-ElGamal randomizers are algebraically annihilated during decryption.

### Technical Note: The Byte-to-Scalar Pipeline
This interactive widget simulates the exact processing of a single attribute (an 8-bit byte) from the access vectors over GF(256). The homomorphic XOR emulation transitions smoothly between three mathematical domains:

1. **Deconstruction (Finite Field):** An individual ℓ-th attribute from the access vector is strictly mapped to an 8-bit binary representation (x, y ∈ {0, 1}⁸).
2. **Base-3 Packing (Scalar Ring):** These 8 bits are weighted and packed into a single carry-free scalar value (η = 8, maximum scalar sum = 6560).
3. **Cryptographic Layer (Elliptic Curve):** The server homomorphically adds these packed scalars across ciphertexts using standard EC point addition. The simulation details the EC-ElGamal layer, illustrating how random ephemeral scalars (ρ₁, ρ₂) mask the points and how these masks are subsequently annihilated by the receiver's private key.
4. **Unpacking (Arithmetic):** The receiver resolves the short-interval ECDLP via the Gaudry-Schost algorithm to recover the sum, then iteratively extracts the exact XORed bits via modulo-3 and modulo-2 arithmetic.
5. **Reassembly (Finite Field):** The reconstructed bits are assembled back into the exact bitwise XOR difference (denoted as 𝔢ₗ ∈ GF(256)), successfully demonstrating a carry-free XOR operation over the original inputs.

### System Requirements
* **Dependencies:** None. The demonstration relies entirely on standard vanilla HTML, CSS, and JavaScript.
* **Network:** No internet connection is required to run the simulation after downloading.
* **Compatibility:** Works on any modern web browser (Google Chrome, Mozilla Firefox, Apple Safari, Microsoft Edge, etc.).

### How to Run the Demonstration
1. Download the `a-scheme-base3-demo.html` file to your local machine.
2. Double-click the downloaded `.html` file. It will automatically open in your default web browser.
3. Use the interactive buttons to toggle the individual bits (xₖ, yₖ) of the Sender's and Receiver's attributes.
4. Click the **"Evaluate Homomorphic Crypto Pipeline ↓"** button to step through the Server-Side blind addition, the Client-Side mask annihilation, and the Base-3 extraction math.
5. Click the **"↻ Generate New Random Attributes & Restart"** button at the bottom to quickly test the mathematical consistency against different random bit combinations.

### Security & Privacy Note
This is a purely client-side simulation. No data is transmitted, and no external libraries or APIs are called.

### 📚 Academic Citation

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.23574958.svg)](https://doi.org/10.5281/zenodo.23574958)

If you utilize these scripts in your research,
please cite the associated archive:

```bash
@misc{chmora2026ascheme,
  author       = {Andrey Chmora},
  title        = {The A-Scheme for Information-Theoretic Covert Transport},
  month        = {Oct},
  year         = {2026},
  publisher    = {Zenodo},
  doi          = 10.5281/zenodo.23536594
  url          = [https://zenodo.org/badge/DOI/10.5281/zenodo.23574958.svg](https://doi.org/10.5281/zenodo.23574958)
```
