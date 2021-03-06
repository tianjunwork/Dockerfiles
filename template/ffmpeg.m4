# Fetch FFmpeg source
ARG FFMPEG_VER=n4.1
ARG FFMPEG_REPO=https://github.com/FFmpeg/FFmpeg/archive/${FFMPEG_VER}.tar.gz
ARG FFMPEG_FLV_PATCH_REPO=https://raw.githubusercontent.com/VCDP/CDN/master/The-RTMP-protocol-extensions-for-H.265-HEVC.patch
ARG FFMPEG_1TN_PATCH_REPO=https://patchwork.ffmpeg.org/patch/11625/raw
ARG FFMPEG_THREAD_PATCH_REPO=https://patchwork.ffmpeg.org/patch/11035/raw
ARG FFMPEG_MA_PATCH_REPO_01=https://raw.githubusercontent.com/VCDP/FFmpeg-patch/master/media-analytics/0001-Intel-inference-engine-detection-filter.patch
ARG FFMPEG_MA_PATCH_REPO_02=https://raw.githubusercontent.com/VCDP/FFmpeg-patch/master/media-analytics/0002-New-filter-to-do-inference-classify.patch
ARG FFMPEG_MA_PATCH_REPO_03=https://raw.githubusercontent.com/VCDP/FFmpeg-patch/master/media-analytics/0003-iemetadata-convertor-muxer.patch
ARG FFMPEG_MA_PATCH_REPO_04=https://raw.githubusercontent.com/VCDP/FFmpeg-patch/master/media-analytics/0004-Kafka-protocol-producer.patch
ARG FFMPEG_MA_PATCH_REPO_05=https://raw.githubusercontent.com/VCDP/FFmpeg-patch/master/media-analytics/0005-Support-object-detection-and-featured-face-identific.patch
ARG FFMPEG_MA_PATCH_REPO_06=https://raw.githubusercontent.com/VCDP/FFmpeg-patch/master/media-analytics/0006-Send-metadata-in-a-packet-and-refine-the-json-format.patch
ARG FFMPEG_MA_PATCH_REPO_07=https://raw.githubusercontent.com/VCDP/FFmpeg-patch/master/media-analytics/0007-Refine-features-of-IE-filters.patch
ARG FFMPEG_MA_PATCH_REPO_08=https://raw.githubusercontent.com/VCDP/FFmpeg-patch/master/media-analytics/0008-fixed-extra-comma-in-iemetadata.patch
ARG FFMPEG_MA_PATCH_REPO_09=https://raw.githubusercontent.com/VCDP/FFmpeg-patch/master/media-analytics/0009-add-source-as-option-source-url-calculate-nano-times.patch
define(`FFMPEG_SUBTITLE',ifelse(index(DOCKER_IMAGE,-dev),-1,OFF,ON))dnl
define(`FFMPEG_X11',ifelse(index(DOCKER_IMAGE,-dev),-1,ifelse(index(DOCKER_IMAGE,xeon-),-1,ON,OFF),ON))dnl

ifelse(index(DOCKER_IMAGE,ubuntu),-1,,
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y -q --no-install-recommends ifelse(FFMPEG_SUBTITLE,ON,libass-dev libfreetype6-dev )ifelse(index(DOCKER_IMAGE,xeon-),-1,libvdpau-dev )ifelse(FFMPEG_X11,ON,libsdl2-dev libxcb1-dev libxcb-shm0-dev libxcb-xfixes0-dev )ifelse(index(DOCKER_IMAGE,-dev),-1,,texinfo )zlib1g-dev libssl-dev
)dnl
ifelse(index(DOCKER_IMAGE,centos),-1,,
RUN yum install -y -q ifelse(FFMPEG_SUBTITLE,ON,libass-devel freetype-devel )ifelse(FFMPEG_X11,ON,SDL2-devel libxcb-devel )ifelse(index(DOCKER_IMAGE,xeon-),-1,libvdpau-devel )ifelse(index(DOCKER_IMAGE,-dev),-1,,texinfo )zlib-devel openssl-devel
)dnl

RUN wget -O - ${FFMPEG_REPO} | tar xz && mv FFmpeg-${FFMPEG_VER} FFmpeg && \
    cd FFmpeg && \
    wget -O - ${FFMPEG_FLV_PATCH_REPO} | patch -p1 && \
    wget -O - ${FFMPEG_1TN_PATCH_REPO} | patch -p1 && \
    wget -O - ${FFMPEG_THREAD_PATCH_REPO} | patch -p1 && \
    wget -O - ${FFMPEG_MA_PATCH_REPO_01} | patch -p1 && \
    wget -O - ${FFMPEG_MA_PATCH_REPO_02} | patch -p1 && \
    wget -O - ${FFMPEG_MA_PATCH_REPO_03} | patch -p1 && \
    wget -O - ${FFMPEG_MA_PATCH_REPO_04} | patch -p1 && \
    wget -O - ${FFMPEG_MA_PATCH_REPO_05} | patch -p1 && \
    wget -O - ${FFMPEG_MA_PATCH_REPO_06} | patch -p1 && \
    wget -O - ${FFMPEG_MA_PATCH_REPO_07} | patch -p1 && \
    wget -O - ${FFMPEG_MA_PATCH_REPO_08} | patch -p1 && \
    wget -O - ${FFMPEG_MA_PATCH_REPO_09} | patch -p1;

defn(`FFMPEG_SOURCE_SVT_HEVC',`FFMPEG_SOURCE_SVT_AV1',`FFMPEG_SOURCE_TRANSFORM360')dnl
# Compile FFmpeg
RUN cd /home/FFmpeg && \
    ./configure --prefix="/usr" --libdir=ifelse(index(DOCKER_IMAGE,ubuntu),-1,/usr/lib64,/usr/lib/x86_64-linux-gnu) --extra-libs="-lpthread -lm" --enable-defn(`BUILD_LINKAGE') --enable-gpl ifelse(FFMPEG_SUBTITLE,ON,--enable-libass --enable-libfreetype) ifelse(FFMPEG_X11,OFF,--disable-xlib --disable-sdl2) --enable-openssl --enable-nonfree ifelse(index(DOCKER_IMAGE,xeon-),-1,--enable-libdrm --enable-libmfx,--disable-vaapi --disable-hwaccels) ifelse(index(DOCKER_IMAGE,-dev),-1,--disable-doc --disable-htmlpages --disable-manpages --disable-podpages --disable-txtpages) defn(`FFMPEG_CONFIG_FDKAAC',`FFMPEG_CONFIG_MP3LAME',`FFMPEG_CONFIG_OPUS',`FFMPEG_CONFIG_VORBIS',`FFMPEG_CONFIG_VPX',`FFMPEG_CONFIG_X264',`FFMPEG_CONFIG_X265',`FFMPEG_CONFIG_AOM',`FFMPEG_CONFIG_SVT_HEVC',`FFMPEG_CONFIG_SVT_AV1',`FFMPEG_CONFIG_TRANSFORM360',`FFMPEG_CONFIG_DLDT_IE',`FFMPEG_CONFIG_LIBRDKAFKA') && \
    make -j8 && \
    make install DESTDIR="/home/build"

define(`INSTALL_PKGS_FFMPEG',dnl
ifelse(index(DOCKER_IMAGE,ubuntu1604),-1,,ifelse(FFMPEG_X11,ON,libxv1 libxcb-shm0 libxcb-shape0 libxcb-xfixes0 libsdl2-2.0-0 libasound2) ifelse(index(DOCKER_IMAGE,xeon-),-1,libvdpau1) libnuma1 ifelse(FFMPEG_SUBTITLE,ON,libass5) libssl1.0.0 ) dnl
ifelse(index(DOCKER_IMAGE,ubuntu1804),-1,,ifelse(FFMPEG_X11,ON,libxv1 libxcb-shm0 libxcb-shape0 libxcb-xfixes0 libsdl2-2.0-0 libasound2) ifelse(index(DOCKER_IMAGE,xeon-),-1,libvdpau1) libnuma1 ifelse(FFMPEG_SUBTITLE,ON,libass9) libssl1.1 libpciaccess0 ) dnl
ifelse(index(DOCKER_IMAGE,centos),-1,,ifelse(FFMPEG_X11,ON,libxcb SDL2) ifelse(FFMPEG_SUBTITLE,ON,libass) numactl ifelse(index(DOCKER_IMAGE,xeon-),-1,libvdpau) ) dnl
)dnl
