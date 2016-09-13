#!/bin/sh

# directories
SOURCE="ffmpeg-3.1.3"
DEST=`pwd`/"ffmpeg-source"/$SOURCE
FAT=`pwd`

SCRATCH=`pwd`/"scratch"
# must be an absolute path
THIN=`pwd`/"thin"

CONFIGURE_FLAGS="--enable-cross-compile --disable-debug --disable-programs \
		 --disable-avdevice --enable-openssl \
                 --disable-doc --enable-pic \
		 --disable-decoder=ac3 --disable-decoder=ac3_at --disable-decoder=ac3_fixed --disable-decoder=eac3 \
		 --disable-decoder=truehd --disable-decoder=dca"


ARCHS="arm64 armv7 x86_64 i386"

COMPILE="y"
LIPO="y"

DEPLOYMENT_TARGET="6.0"

if [ "$*" ]
then
	if [ "$*" = "lipo" ]
	then
		# skip compile
		COMPILE=
	else
		ARCHS="$*"
		if [ $# -eq 1 ]
		then
			# skip lipo
			LIPO=
		fi
	fi
fi

if [ "$COMPILE" ]
then
	if [ ! `which yasm` ]
	then
		echo 'Yasm not found'
		if [ ! `which brew` ]
		then
			echo 'Homebrew not found. Trying to install...'
                        ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" \
				|| exit 1
		fi
		echo 'Trying to install Yasm...'
		brew install yasm || exit 1
	fi
	if [ ! `which gas-preprocessor.pl` ]
	then
		echo 'gas-preprocessor.pl not found. Trying to install...'
		(curl -L https://github.com/libav/gas-preprocessor/raw/master/gas-preprocessor.pl \
			-o /usr/local/bin/gas-preprocessor.pl \
			&& chmod +x /usr/local/bin/gas-preprocessor.pl) \
			|| exit 1
	fi

	if [ ! -r $DEST ]
	then
		mkdir -p `pwd`/ffmpeg-source
		echo 'FFmpeg source not found. Trying to download... from '"https://www.ffmpeg.org/releases/$SOURCE.tar.bz2"
		curl https://www.ffmpeg.org/releases/$SOURCE.tar.bz2 | tar xj -C `pwd`/ffmpeg-source \
			|| exit 1
	fi

	CWD=`pwd`
	for ARCH in $ARCHS
	do
		echo "building $ARCH..."
		mkdir -p "$SCRATCH/$ARCH"
		cd "$SCRATCH/$ARCH"

		CFLAGS="-arch $ARCH"
		if [ "$ARCH" = "i386" -o "$ARCH" = "x86_64" ]
		then
		    PLATFORM="iPhoneSimulator"
		    CFLAGS="$CFLAGS -mios-simulator-version-min=$DEPLOYMENT_TARGET"
		else
		    PLATFORM="iPhoneOS"
		    CFLAGS="$CFLAGS -mios-version-min=$DEPLOYMENT_TARGET -fembed-bitcode"
		    if [ "$ARCH" = "arm64" ]
		    then
		        EXPORT="GASPP_FIX_XCODE5=1"
		    fi
		fi

		XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
		CC="xcrun -sdk $XCRUN_SDK clang"
		CXXFLAGS="$CFLAGS"
		LDFLAGS="$CFLAGS -L../../../openssl/lib"
		CFLAGS="$CFLAGS -I../../../openssl/include"
		if [ "$X264" ]
		then
			CFLAGS="$CFLAGS -I$X264/include"
			LDFLAGS="$LDFLAGS -L$X264/lib"
		fi
		if [ "$FDK_AAC" ]
		then
			CFLAGS="$CFLAGS -I$FDK_AAC/include"
			LDFLAGS="$LDFLAGS -L$FDK_AAC/lib"
		fi

		TMPDIR=${TMPDIR/%\/} $DEST/configure \
		    --target-os=darwin \
		    --arch=$ARCH \
		    --cc="$CC" \
		    $CONFIGURE_FLAGS \
		    --extra-cflags="$CFLAGS" \
		    --extra-ldflags="$LDFLAGS" \
		    --prefix="$THIN/$ARCH" \
		|| exit 1

		make -j3 install $EXPORT || exit 1
		cd $CWD
	done
fi

if [ "$LIPO" ]
then
	echo "building fat binaries..."
	mkdir -p $FAT/lib
	set - $ARCHS
	CWD=`pwd`
	cd $THIN/$1/lib
	for LIB in *.a
	do
		cd $CWD
		echo lipo -create `find $THIN -name $LIB` -output $FAT/lib/$LIB 1>&2
		lipo -create `find $THIN -name $LIB` -output $FAT/lib/$LIB || exit 1
	done

	cd $CWD
	mv -f $THIN/$1/include $FAT
fi

cp $DEST/LICENSE.md ./
rm -rf $THIN
rm -rf $SCRATCH

echo Done
