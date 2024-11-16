ARG MAKE_JOBS="1"
ARG DEBIAN_FRONTEND="noninteractive"

FROM python:3.8-slim AS base
FROM buildpack-deps:buster AS base-builder

FROM base-builder AS mrtrix3-builder

# Git commitish from which to build MRtrix3.
ARG MRTRIX3_GIT_COMMITISH="master"
# Command-line arguments for `./configure`
ARG MRTRIX3_CONFIGURE_FLAGS=""
# Command-line arguments for `./build`
ARG MRTRIX3_BUILD_FLAGS="-persistent -nopaginate"

RUN apt-get -qq update \
    && apt-get install -yq --no-install-recommends \
        libeigen3-dev \
        libfftw3-dev \
        libpng-dev \
        libqt5opengl5-dev \
        libqt5svg5-dev \
        qt5-default \
        qtbase5-dev \
        zlib1g-dev \
    && apt-get remove -yq \
        libtiff-dev \
        libtiff5-dev \
    && rm -rf /var/lib/apt/lists/*

# Clone, build, and install MRtrix3.
ARG MAKE_JOBS
WORKDIR /opt/mrtrix3
RUN git clone -b $MRTRIX3_GIT_COMMITISH --depth 1 https://github.com/MRtrix3/mrtrix3.git . \
    && ./configure $MRTRIX3_CONFIGURE_FLAGS \
    && NUMBER_OF_PROCESSORS=$MAKE_JOBS ./build $MRTRIX3_BUILD_FLAGS \
    && rm -rf tmp

# Download minified ART ACPCdetect (V2.0).
FROM base-builder AS acpcdetect-installer
WORKDIR /opt/art
RUN curl -fsSL https://osf.io/73h5s/download \
    | tar xz --strip-components 1

# Download minified ANTs (2.3.4-2).
FROM base-builder AS ants-installer
WORKDIR /opt/ants
RUN curl -fsSL https://osf.io/yswa4/download \
    | tar xz --strip-components 1

# Download FreeSurfer files.
FROM base-builder AS freesurfer-installer
WORKDIR /opt/freesurfer
RUN curl -fsSLO https://raw.githubusercontent.com/freesurfer/freesurfer/v7.1.1/distribution/FreeSurferColorLUT.txt

# Download minified FSL (6.0.4-2)
FROM base-builder AS fsl-installer
WORKDIR /opt/fsl
RUN curl -fsSL https://osf.io/dtep4/download \
    | tar xz --strip-components 1

# TODO Download workshop material
# TODO Ideally demonstrate this using datalad
FROM base-builder AS data-downloader
#WORKDIR /data
#RUN pip3 install \
#        datalad \
#        datalad-osf
#datalad clone osf://sn9bk/ dwifslpreproc
WORKDIR /data/dwifslpreproc
RUN curl https://files.au-1.osf.io/v1/resources/sn9bk/providers/osfstorage/6721a5168a5072a07cbfa7e3/?zip= -o DICOM.zip \
    && unzip DICOM.zip -d DICOM/ \
    && rm DICOM.zip \
    && curl https://files.au-1.osf.io/v1/resources/sn9bk/providers/osfstorage/6721cf089308ab9319629987/?zip= -o out.zip \
    && unzip out.zip -d out/ \
    && rm out.zip \
    && curl https://osf.io/kfyn9/download -o process.sh

# Build final image.
FROM base AS final
WORKDIR /data

# Install runtime system dependencies.
RUN apt-get -qq update \
    && apt-get install -yq --no-install-recommends \
        binutils \
        dc \
        fuse-overlayfs \
        less \
        libfftw3-double3 \
        libgl1-mesa-glx \
        libgomp1 \
        liblapack3 \
        libpng16-16 \
        libqt5core5a \
        libqt5gui5 \
        libqt5network5 \
        libqt5svg5 \
        libqt5widgets5 \
        libquadmath0 \
        nano \
        python3-distutils \
        vim \
    && rm -rf /var/lib/apt/lists/*

COPY --from=acpcdetect-installer /opt/art /opt/art
COPY --from=ants-installer /opt/ants /opt/ants
COPY --from=freesurfer-installer /opt/freesurfer /opt/freesurfer
COPY --from=fsl-installer /opt/fsl /opt/fsl
COPY --from=mrtrix3-builder /opt/mrtrix3 /opt/mrtrix3
COPY --from=data-downloader --chmod=444 /data /overlayfs/readonly
COPY bashrc /root/.bashrc

RUN mkdir /overlayfs/local /overlayfs/work
RUN echo "overlay /data overlay defaults,lowerdir=/overlayfs/readonly,upperdir=/overlayfs/local,workdir=/overlayfs/work 0 2" >> /etc/fstab

CMD ["/bin/bash"]
