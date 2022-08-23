# YALDPC

## Yet another LDPC MEX toolkit for MATLAB 
### (and perhaps even GNU Octave) 
### contains:

1. Hbm matrices of QC-LDPC codes used in Wi-Fi 6 and WiMAX standards (IEEE802.11-2020 and IEEE 802.16-2017).

2. Two C99 implementations of a QCLDP-encoder: One universal array encoder, that stores each bit in a whole byte and supports all LDPC codes in 1. Plus another bitmap encoder that stores bits efficiently in a bitmap, but support only codes with parameters N, K, Z divisible by 8. (Which means no Wi-Fi 6 LDPC support). These are switchable by a preprocessor macro.

3. Two C99 implementations of a single-scan min-sum QCLDPC-layered decoder: One floating point and one fixed point. Switchable by a preprocessors macro. No saturating arithmetic and no advanced optimizations, such as intrisics, are used. Single-thread and multi-threaded versions of the decoder are available.

4. MEX wrappers and MATLAB m-files for convenient usage of both encoders and decoders in MATLAB.

5. Set of supporting MATLAB scripts primarily for evaluating waterfall EbN0-vs-BER curves.

All files released under the BSD licence.
In order to use the MEX files, you need MATLAB. If you're only interested in using 1, 2, and 3 no proprietary software is needed.

## To run it from MATLAB:

To just generate ldpc.h and ldpc.c with important code/encoder/decoder defines run createHeaderFile.m, this should also work in GNU Octave.

To test the encoder and see examples of how it's used run testEnc.m
To test the decoder and see examples of how it's used run testDec.m

To run a set of waterfall simulations for an 'array' encoder run simArray.m.
To run a set of waterfall simulations for a 'bitmap' encoder run simBitmap.m.

To run a decoder benchmark and compare it to the ldpcDecode() Communications Toolbox run benchmarDecoder.m.

Tested on: Ubuntu 18.04 LTS MATLAB R2021b and Ubuntu 20.04 LTS MATLAB R2022a

## To run it from Linux terminal:

Compile CLI benchmark: 
```
cd MEX
c99 -O3 -DNDEBUG -o main main.c decoder.c encoder.c ldpc.c debug.c ; ./main
```
A single-thread benchmark should take about a minute.

May also work on Windows, who cares ? :)

## Reading:

1. Gallager, Robert G. Low-Density Parity-Check Codes. Cambridge, MA: MIT Press, 1963

2. M. Fossorier, M. Mihaljevic, and H. Imai, “Reduced complexity iterative decoding of low density parity check codes based on belief propagation,” IEEE Transactions on Communications, vol. 47, pp. 673–680, May 1999.

3. Hocevar, D.E. "A reduced complexity decoder architecture via layered decoding of LDPC codes." In IEEE Workshop on Signal Processing Systems, 2004. SIPS 2004. doi: 10.1109/SIPS.2004.1363033

4. X. Huang, "Single-Scan Min-Sum Algorithms for Fast Decoding of LDPC Codes," 2006 IEEE Information Theory Workshop - ITW '06 Chengdu, 2006, pp. 140-143, doi: 10.1109/ITW2.2006.323774.

5. IEEE Std. 802.16-2017, IEEE Standard for Air Interface for Broadband Wireless Access Systems, IEEE, 2018, USA. Section 8.4.9.2.5 Low Zensity parity check (LDPC) code pp. 1459 – 1463.

6. IEEE Std. 802.11ax-2021: IEEE Standard for Information Technology—Telecommunications and Information Exchange between Systems Local and Metropolitan Area Networks—Specific Requirements, Part 11: Wireless LAN Medium Access Control (MAC) and Physical Layer (PHY) Specifications Amendment 1: Enhancements for High‐Efficiency WLAN. IEEE, 2021, USA.

7. IEEE Std 802.11-2020 IEEE Standard for Information Technology—Local and  Metropolitan Area Networks—Specific Requirements Part 11:  Wireless LAN MAC and PHY Specifications. IEEE, 2021, USA. Annex F: HT LDPC matrix definitions. pp. 4130 – 4132
