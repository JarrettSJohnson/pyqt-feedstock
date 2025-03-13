set -exou

pushd pyqt
cp LICENSE ..

SIP_COMMAND="sip-build"
EXTRA_FLAGS=""

echo PREFIX=${PREFIX}
echo BUILD_PREFIX=${BUILD_PREFIX}
USED_BUILD_PREFIX=${BUILD_PREFIX:-${PREFIX}}
echo USED_BUILD_PREFIX=${BUILD_PREFIX}

MAKE_JOBS=$CPU_COUNT
export NINJAFLAGS="-j${MAKE_JOBS}"

# For QDoc
export LLVM_INSTALL_DIR=${PREFIX}

# Remove the full path from CXX etc. If we don't do this
# then the full path at build time gets put into
# mkspecs/qmodule.pri and qmake attempts to use this.
export AR=$(basename ${AR})
export RANLIB=$(basename ${RANLIB})
export STRIP=$(basename ${STRIP})
export OBJDUMP=$(basename ${OBJDUMP})
export CC=$(basename ${CC})
export CXX=$(basename ${CXX})

# Let Qt set its own flags and vars
for x in OSX_ARCH CFLAGS CXXFLAGS LDFLAGS
do
    unset $x
done

# You can use this to cut down on the number of modules built. Of course the Qt package will not be of
# much use, but it is useful if you are iterating on e.g. figuring out compiler flags to reduce the
# size of the libraries.
MINIMAL_BUILD=no

# if [[ $(uname) == "Linux" ]]; then
#     USED_BUILD_PREFIX=${BUILD_PREFIX:-${PREFIX}}
#     echo USED_BUILD_PREFIX=${BUILD_PREFIX}

#     ln -s ${GXX} g++ || true
#     ln -s ${GCC} gcc || true
#     ln -s ${USED_BUILD_PREFIX}/bin/${HOST}-gcc-ar gcc-ar || true

#     export LD=${GXX}
#     export CC=${GCC}
#     export CXX=${GXX}
#     export PKG_CONFIG_EXECUTABLE=$(basename $(which pkg-config))

#     chmod +x g++ gcc gcc-ar
#     export PATH=${PWD}:${PATH}

#     SYSROOT_FLAGS="-L ${BUILD_PREFIX}/${HOST}/sysroot/usr/lib64 -L ${BUILD_PREFIX}/${HOST}/sysroot/usr/lib"
#     export CFLAGS="$SYSROOT_FLAGS $CFLAGS"
#     export CXXFLAGS="$SYSROOT_FLAGS $CXXFLAGS"
#     export LDFLAGS="$SYSROOT_FLAGS $LDFLAGS"
# fi

if [[ $(uname) == "Linux" ]]; then
    ln -s ${GXX} g++ || true
    ln -s ${GCC} gcc || true
    # Needed for -ltcg, it we merge build and host again, change to ${PREFIX}
    ln -s ${USED_BUILD_PREFIX}/bin/${HOST}-gcc-ar gcc-ar || true

    export LD=${GXX}
    export CC=${GCC}
    export CXX=${GXX}
    export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:/usr/lib64/pkgconfig/"
    chmod +x g++ gcc gcc-ar
    export PATH=${PWD}:${PATH}

    declare -a SKIPS
    if [[ ${MINIMAL_BUILD} == yes ]]; then
      SKIPS+=(-skip); SKIPS+=(qtwebsockets)
      SKIPS+=(-skip); SKIPS+=(qtwebchannel)
      SKIPS+=(-skip); SKIPS+=(qtsvg)
      SKIPS+=(-skip); SKIPS+=(qtsensors)
      SKIPS+=(-skip); SKIPS+=(qtcanvas3d)
      SKIPS+=(-skip); SKIPS+=(qtconnectivity)
      SKIPS+=(-skip); SKIPS+=(declarative)
      SKIPS+=(-skip); SKIPS+=(multimedia)
      SKIPS+=(-skip); SKIPS+=(qttools)
      SKIPS+=(-skip); SKIPS+=(qtlocation)
      SKIPS+=(-skip); SKIPS+=(qt3d)
    fi

    if [ ${target_platform} == "linux-aarch64" ] || [ ${target_platform} == "linux-ppc64le" ]; then
        # The -reduce-relations option doesn't seem to pass for aarch64 and ppc64le
        REDUCE_RELOCATIONS=
    else
        REDUCE_RELOCATIONS=-reduce-relocations
    fi

#     # ${BUILD_PREFIX}/${HOST}/sysroot/usr/lib64 is because our compilers don't look in sysroot/usr/lib64
#     # CentOS7 has:
#     # LIBRARY_PATH=/usr/lib/gcc/x86_64-redhat-linux/4.8.5/:/usr/lib/gcc/x86_64-redhat-linux/4.8.5/../../../../lib64/:/lib/../lib64/:/usr/lib/../lib64/:/usr/lib/gcc/x86_64-redhat-linux/4.8.5/../../../:/lib/:/usr/lib/
#     # We have:
#     # LIBRARY_PATH=/opt/conda/conda-bld/qt_1549795295295/_build_env/bin/../lib/gcc/x86_64-conda_cos6-linux-gnu/7.3.0/:/opt/conda/conda-bld/qt_1549795295295/_build_env/bin/../lib/gcc/:/opt/conda/conda-bld/qt_1549795295295/_build_env/bin/../lib/gcc/x86_64-conda_cos6-linux-gnu/7.3.0/../../../../x86_64-conda_cos6-linux-gnu/lib/../lib/:/opt/conda/conda-bld/qt_1549795295295/_build_env/x86_64-conda_cos6-linux-gnu/sysroot/lib/../lib/:/opt/conda/conda-bld/qt_1549795295295/_build_env/x86_64-conda_cos6-linux-gnu/sysroot/usr/lib/../lib/:/opt/conda/conda-bld/qt_1549795295295/_build_env/bin/../lib/gcc/x86_64-conda_cos6-linux-gnu/7.3.0/../../../../x86_64-conda_cos6-linux-gnu/lib/:/opt/conda/conda-bld/qt_1549795295295/_build_env/x86_64-conda_cos6-linux-gnu/sysroot/lib/:/opt/conda/conda-bld/qt_1549795295295/_build_env/x86_64-conda_cos6-linux-gnu/sysroot/usr/lib/
#     # .. this is probably my fault.
#     # Had been trying with:
#     #   -sysroot ${BUILD_PREFIX}/${HOST}/sysroot
#     # .. but it probably requires changing -L ${BUILD_PREFIX}/${HOST}/sysroot/usr/lib64 to -L /usr/lib64
#     ../configure -prefix ${PREFIX} \
#                 -libdir ${PREFIX}/lib \
#                 -bindir ${PREFIX}/bin \
#                 -headerdir ${PREFIX}/include/qt \
#                 -archdatadir ${PREFIX} \
#                 -datadir ${PREFIX} \
#                 -I ${PREFIX}/include \
#                 -L ${PREFIX}/lib \
#                 -L ${BUILD_PREFIX}/${HOST}/sysroot/usr/lib64 \
#                 -L ${BUILD_PREFIX}/${HOST}/sysroot/usr/lib \
#                 QMAKE_LFLAGS+="-Wl,-rpath,$PREFIX/lib -Wl,-rpath-link,$PREFIX/lib -L$PREFIX/lib" \
#                 -release \
#                 -opensource \
#                 -confirm-license \
#                 -shared \
#                 -nomake examples \
#                 -nomake tests \
#                 -make tools \
#                 -verbose \
#                 -skip wayland \
#                 -skip qtwebengine \
#                 -gstreamer 1.0 \
#                 -system-libjpeg \
#                 -system-libpng \
#                 -system-zlib \
#                 -system-harfbuzz \
#                 -system-sqlite \
#                 -plugin-sql-sqlite \
#                 -plugin-sql-mysql \
#                 -plugin-sql-psql \
#                 -egl \
#                 -eglfs \
#                 -xcb \
#                 -xcb-xlib \
#                 -qt-pcre \
#                 -xkbcommon \
#                 -dbus \
#                 -no-linuxfb \
#                 -no-libudev \
#                 -no-avx \
#                 -no-avx2 \
#                 -optimize-size \
#                 ${REDUCE_RELOCATIONS} \
#                 -cups \
#                 -openssl-linked \
#                 -Wno-expansion-to-defined \
#                 -D _X_INLINE=inline \
#                 -D XK_dead_currency=0xfe6f \
#                 -D _FORTIFY_SOURCE=2 \
#                 -D XK_ISO_Level5_Lock=0xfe13 \
#                 -D FC_WEIGHT_EXTRABLACK=215 \
#                 -D FC_WEIGHT_ULTRABLACK=FC_WEIGHT_EXTRABLACK \
#                 -D GLX_GLXEXT_PROTOTYPES \
#                 "${SKIPS[@]+"${SKIPS[@]}"}"

# # ltcg bloats a test tar.bz2 from 24524263 to 43257121 (built with the following skips)
# #                -ltcg \
# #                --disable-new-dtags \


#   # Shorten the log to a little further on travis and to make the log files smaller
#   # than 50 MB.
#   # Without these sed commands, one gets about 4_497_973 characters in 30 mins
#   # With these sed commands, we get about 1_054_756 characters for getting as
#   # far in the build process.
#   make -j${MAKE_JOBS} | sed "s/^g++.*-o/g++ [...] -o/" | sed "s/-DQT.* //"
#   # make -j${MAKE_JOBS}
#   make install
fi

if [[ $(uname) == "Darwin" ]]; then
    # Use xcode-avoidance scripts
    export PATH=$PREFIX/bin/xc-avoidance:$PATH
fi

if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" == "1" ]]; then
  SIP_COMMAND="$BUILD_PREFIX/bin/python -m sipbuild.tools.build"
  SITE_PKGS_PATH=$($PREFIX/bin/python -c 'import site;print(site.getsitepackages()[0])')
  EXTRA_FLAGS="--target-dir $SITE_PKGS_PATH"
  ln -s ${BUILD_PREFIX}/bin/qmake6 ${BUILD_PREFIX}/bin/qmake
fi
ln -s ${PREFIX}/bin/qmake6 ${PREFIX}/bin/qmake

if test "${CONDA_BUILD_CROSS_COMPILATION:-}" = "1"; then
  echo "" > sip/QtOpenGL/qopenglfunctions_es2.sip
fi

$SIP_COMMAND \
--verbose \
--confirm-license \
--no-make \
$EXTRA_FLAGS

pushd build

if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" == "1" ]]; then
  # Make sure BUILD_PREFIX sip-distinfo is called instead of the HOST one
  cat Makefile | sed -r 's|\t(.*)sip-distinfo(.*)|\t'$BUILD_PREFIX/bin/python' -m sipbuild.distinfo.main \2|' > Makefile.temp
  rm Makefile
  mv Makefile.temp Makefile
fi

CPATH=$PREFIX/include make -j$CPU_COUNT
make install
