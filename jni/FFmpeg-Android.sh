#!/bin/bash
DEST=`pwd`/build/ffmpeg && rm -rf $DEST
FFMPEG_SOURCE=`pwd`/ffmpeg
X264_SOURCE=`pwd`/x264

TOOLCHAIN=/tmp/ffmpeg
SYSROOT=$TOOLCHAIN/sysroot/

export PATH=$TOOLCHAIN/bin:$PATH
export CC="ccache arm-linux-androideabi-gcc"
export LD=arm-linux-androideabi-ld
export AR=arm-linux-androideabi-ar

CFLAGS="-O3 -Wall -mthumb -pipe -fpic -fasm \
  -finline-limit=300 -ffast-math \
  -fstrict-aliasing -Werror=strict-aliasing \
  -fmodulo-sched -fmodulo-sched-allow-regmoves \
  -Wno-psabi -Wa,--noexecstack \
  -D__ARM_ARCH_5__ -D__ARM_ARCH_5E__ -D__ARM_ARCH_5T__ -D__ARM_ARCH_5TE__ \
  -DANDROID -DNDEBUG"

X264_FLAGS="--cross-prefix=arm-linux-androideabi- \
--enable-pic --enable-static -Wl --fix-cortex-a8 \
--prefix=$PREFIX \
--host=arm-linux"

FFMPEG_FLAGS="--target-os=linux \
  --arch=arm \
  --enable-cross-compile \
  --cross-prefix=arm-linux-androideabi- \
  --enable-shared \
  --disable-symver \
  --disable-doc \
  --disable-ffplay \
  --disable-ffmpeg \
  --disable-ffprobe \
  --disable-ffserver \
  --enable-protocols  \
  --enable-fft \
  --enable-rdft \
  --enable-pthreads \
  --enable-parsers \
  --enable-demuxers \
  --enable-decoders \
  --enable-bsfs \
  --enable-network \
  --enable-swscale  \
  --enable-swresample  \
  --enable-avresample \
  --enable-hwaccels \
  --enable-decoder=rawvideo \
  --enable-encoder=aac,libx264 \
  --enable-libx264 \
  --enable-asm \
  --enable-gpl \
  --enable-version3"

if [ -d $TOOLCHAIN ]; then
    echo "Toolchain is already built."
else
    $ANDROID_NDK/build/tools/make-standalone-toolchain.sh --platform=android-14 --install-dir=$TOOLCHAIN
fi


if [ "$(ls -A $X264_SOURCE)" ] && [ "$(ls -A $FFMPEG_SOURCE)" ]; then
    echo "libx264 and ffmpeg are already cloned."
else
    git submodule update --init
fi

if [ -f $X264_SOURCE/libx264.a ]; then
    echo "libx264 is already built."
else
    echo "configure and make x264"
    cd $X264_SOURCE
   ./configure $X264_FLAGS
    make STRIP=
fi

for version in armv7; do

  cd $FFMPEG_SOURCE

  case $version in
    armv7)
      EXTRA_CFLAGS="-march=armv7-a -mfpu=vfpv3-d16 -mfloat-abi=softfp"
      EXTRA_LDFLAGS="-Wl,--fix-cortex-a8"
      LIB_SUB="armeabi-v7a"
      LOCAL_ARM_NEON= false
      ;;
    *)
      EXTRA_CFLAGS=""
      EXTRA_LDFLAGS=""
      ;;
  esac

  PREFIX="$DEST/$version" && mkdir -p $PREFIX
  FFMPEG_FLAGS="$FFMPEG_FLAGS --prefix=$PREFIX"

  echo "Configure ffmpeg for $version."
  ./configure $FFMPEG_FLAGS --extra-cflags="$CFLAGS $EXTRA_CFLAGS -I$X264_SOURCE" --extra-ldflags="$EXTRA_LDFLAGS -L$X264_SOURCE" | tee $PREFIX/configuration.txt
  cp config.* $PREFIX
  [ $PIPESTATUS == 0 ] || exit 1

  make clean
  make -j4 || exit 1
  make install || exit 1

  rm libavcodec/inverse.o

  cd ..
  $ANDROID_NDK/ndk-build -d -e TARGET_ARCH_ABI=$LIB_SUB LOCAL_ARM_NEON=$LOCAL_ARM_NEON
  #mv ../libs/armeabi ../libs/$LIB_SUB
  #$CC -lm -lz -shared --sysroot=$SYSROOT -Wl,--no-undefined -Wl,-z,noexecstack $EXTRA_LDFLAGS libavutil/*.o libavutil/arm/*.o libavcodec/*.o libavcodec/arm/*.o libavformat/*.o libswresample/*.o libswscale/*.o -o $PREFIX/libffmpeg.so

  #cp $PREFIX/libffmpeg.so $PREFIX/libffmpeg-debug.so
  #arm-linux-androideabi-strip --strip-unneeded $PREFIX/libffmpeg.so

done
