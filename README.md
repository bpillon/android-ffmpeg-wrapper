android-ffmpeg-wrapper
======================


Java FFmpeg wrapper with updated version of Vine FFmpeg-Android (https://github.com/vine/FFmpeg-Android) to build FFmpeg 2.3 with x264 for Android armv7

Build
-----

0. Install git, Android ndk
1. `$ export ANDROID_NDK=/path/to/your/android-ndk`
2. `$ cd jni`
3. `$ ./FFmpeg-Android.sh`
4. libencoding.so and libffmpeginvoke.so will be built to `build/ffmpeg/armv7/`
