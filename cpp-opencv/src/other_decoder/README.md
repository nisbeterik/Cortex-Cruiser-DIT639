
This directory (other_decoder) is used to save files for when I tried using other decoder logic than <libyuv.h> and <wels/codec_api.h>, more specifially FFMPEG

Either way, there are issues trying to build using docker in terms of dependencies no matter which option.
For some reason, the application does not find any reference to methods and types used by decoding libraries.

Issue could lie with CMAKE and linking/finding stuff, or with the Dockerfile. I don't know yet.
