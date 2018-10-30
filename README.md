# Compensation of nonlinear sound card distortions for audio measurements
WIP
## Generating and Configuring the Compensation Polynom:
1. Record closed-loop stereo wav

Start playback:
```
sox -v -r 48000 -c 2 -n -b 32 -t alsa hw:CARD synth 1000000 sine 1k gain -3
```
Start capture while playback is running:
```
sox -v -b 32 -t alsa hw:CARD recorded.wav
```
Make sure no clipping occurs while recording.

2. Determine phase shift and check frequency
* octave, script measure_phase.m 
* enter correct path to the recorded wav
* output - phaseshift, offset, resp. precise frequency (at least to 6 decimal points)
* check for both channels - should generate identical values

3. Calculate compensation polynomial
* octave, script gen_compen_polynom.m
* enter correct path to the recorded wav
* put measured phaseshift and offset, resp. precise frequency
* adjust refGain value to fit reference first harmonic to recorded first harmonic + keep the linear gain (second polynomial coeff) < 1 to avoid clipping
* output - polynomial coeffs - run for each channel

4. Create capture device in .asoundrc
```
pcm.calibrated_in {
         type route
         slave {
                 pcm "hw:CARD"
                 channels 2
         }
         ttable {
                 0.0 { polynom [-4.61863286479129e-06   9.93504664105402e-01   1.52712702588027e-05   5.34792954092116e-05   1.50194140386266e-05  -6.87469377116849e-05 ] }
                 1.1 { polynom [ -1.28241538261851e-06   9.97345275703695e-01   2.61617549722846e-06   4.51838018746386e-05   1.03336561333305e-05  -8.87928889608999e-05 ] }
         }
}
```
## Patched alsa route plugin

The repository contains pre-compiled libasound.2.0.0 file (both amd64 and i386) for 
* alsa-lib v. 1.0.27 (Ubuntu 14.04 and derivates)
* alsa-lib v. 1.1.0 (Ubuntu 16.04 and derivates)

Just copy the library to /usr/lib/x86_64-linux-gnu (i386-linux-gnu resp.). You can check the patched version with
```
strings libasound.so.2.0.0 | grep poly
polynom
Too many polynom coefficients for slave: %s, maximum %d, requested %d
Invalid polynom coefficient for slave: %s
poly_node_it
poly_nextit
poly_node
poly_node_id
```
Eventually I will create a patch against HEAD of upstream alsa-lib. But compiling HEAD alsa-lib version requires recompiling all the clients.
