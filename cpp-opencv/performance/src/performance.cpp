
#include "cluon-complete.hpp"
#include "opendlv-standard-message-set.hpp"
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include <fstream>
#include <chrono>
#include <ctime>
#include <iostream>
#include <sstream>
#include <string>
#include <iomanip>
#include <libyuv.h>
#include <wels/codec_api.h>
#include "steering.hpp"

float THRESHOLD = 0.09;
constexpr const bool AUTOREWIND{false};
constexpr const bool THREADING{false};

int32_t main(int32_t argc, char **argv)
{
    auto commandlineArguments = cluon::getCommandlineArguments(argc, argv);
    // parse recording file path in arguments and --verbose flag
    if (commandlineArguments.count("rec") == 0)
    {
        std::cerr << argv[0] << " requires a recording file to process." << std::endl;
        std::cerr << "Usage:   " << argv[0] << " --rec=<Recording.rec> [--verbose]" << std::endl;
        std::cerr << "Example: " << argv[0] << " --rec=myRecording.rec" << std::endl;
        return 1;
    }

    // Add output file path handling
    std::string outputPath = "output.csv";  // Default
    std::string currentOutputPath = "current_output.csv";
    if (commandlineArguments.count("output") > 0) {
        outputPath = commandlineArguments["output"];
        // Insert "_current" before the file extension
        size_t dotPos = outputPath.find_last_of(".");
        if (dotPos != std::string::npos) {
            currentOutputPath = outputPath.substr(0, dotPos) + "_current" + outputPath.substr(dotPos);
        } else {
            currentOutputPath = outputPath + "_current";
        }
    } else {
        currentOutputPath = "output_current.csv";
    }
    // Open file with error checking
    std::ofstream computedFile(outputPath);
    if (!computedFile.is_open()) {
        std::cerr << "Error: Could not open output file at " << outputPath << std::endl;
        return 1;
    }
    computedFile << "prevGroundSteering\n";

    std::ofstream computedCurrent(currentOutputPath);
     
    if (!computedCurrent.is_open()) {
        std::cerr << "Error: Could not open output file at " << currentOutputPath << std::endl;
        return 1;
    } 
    computedCurrent << "timestamp,groundTruth,groundSteering\n";

    const std::string recFile = commandlineArguments["rec"];
    bool verbose = (commandlineArguments.count("verbose") != 0);
    cluon::Player player(recFile, AUTOREWIND, THREADING); // pass recording file and other parameters to Player object
    opendlv::proxy::GroundSteeringRequest gsr;            // variable to store gsr message
    opendlv::proxy::ImageReading img;                     // variable to store imagereading message
    cluon::data::TimeStamp ts;                            // TimeStamp object to store timestamp
    double calculatedSteering;                            // The steering calculated using our algorithm
    int64_t ts_ms;                                        // variable to store timestamp in millieseconds
    int failures = 0;                                     // counts frames that failed to decode / process
    bool hasAngle = false;                                // variable to keep track if image frame has equivalent gsr data
    int totalValid = 0;                                   // Amount of valid ground truth values
    int withinRange = 0;                                  // Amount of calculated steering angles within range
    float acc = 0;                                        // Accuracy of algorithm compared to truth steering values
    
    // Initialize the decoder
    ISVCDecoder *decoder = nullptr;
    WelsCreateDecoder(&decoder);
    if (!decoder)
    {
        std::cerr << "Failed to create decoder" << std::endl;
        return 1;
    }

    SDecodingParam decoding_param;
    memset(&decoding_param, 0, sizeof(SDecodingParam));
    decoding_param.eEcActiveIdc = ERROR_CON_DISABLE;
    decoding_param.bParseOnly = false;
    decoding_param.sVideoProperty.eVideoBsType = VIDEO_BITSTREAM_DEFAULT;

    if (cmResultSuccess != decoder->Initialize(&decoding_param))
    {
        std::cerr << "Failed to initialize decoder" << std::endl;
        return 1;
    }
   
    // loop that ends when .rec file has no more data
    while (player.hasMoreData())
    {
        auto next = player.getNextEnvelopeToBeReplayed(); // get next envelope of .rec file
        if (next.first)
        {
            cluon::data::Envelope envelope = next.second; // store current envelope
            // if datatype is ImageReading (see opendlv-standard-message-set)
            if (envelope.dataType() == 1055)
            {
                if (hasAngle)
                {
                    img = cluon::extractMessage<opendlv::proxy::ImageReading>(std::move(envelope));
                    // Note: The following segment is code taken, but appropriated, from here ->
                    // https://github.com/chalmers-revere/opendlv-video-h264-decoder/blob/master/src/opendlv-video-h264-decoder.cpp
                    // Check if the image encoding is H264.
                    if ("h264" == img.fourcc())
                    {
                        const uint32_t WIDTH = img.width();
                        const uint32_t HEIGHT = img.height();
                        // Prepare the buffer for decoding.
                        uint8_t *yuvData[3]; // Pointers to Y, U, and V planes.
                        SBufferInfo bufferInfo;
                        memset(&bufferInfo, 0, sizeof(SBufferInfo));
                        // Retrieve the H264 data from the message.
                        std::string data{img.data()};
                        const uint32_t LEN = static_cast<uint32_t>(data.size());
                        // Decode the H264 frame.
                        if (0 != decoder->DecodeFrame2(reinterpret_cast<const unsigned char *>(data.c_str()), LEN, yuvData, &bufferInfo))
                        {
                            failures++;
                        }
                        else
                        {
                            // If the decoding is successful and the buffer is valid.
                            if (1 == bufferInfo.iBufferStatus)
                            {
                                // Convert the YUV data to a cv::Mat in BGR format.
                                cv::Mat bgrImage(HEIGHT, WIDTH, CV_8UC3);
                                libyuv::I420ToRGB24(
                                    yuvData[0], bufferInfo.UsrData.sSystemBuffer.iStride[0], // Y plane.
                                    yuvData[1], bufferInfo.UsrData.sSystemBuffer.iStride[1], // U plane.
                                    yuvData[2], bufferInfo.UsrData.sSystemBuffer.iStride[1], // V plane.
                                    bgrImage.data, WIDTH * 3,                                // Destination (BGR format).
                                    WIDTH, HEIGHT                                            // Dimensions.
                                );
                                // Process frame to calculate steering
                                calculatedSteering = processFrame(bgrImage, verbose);
                                
                                // Determine difference between calculated and truth values, unless gsr is 0
                                if (gsr.groundSteering() != 0)
                                {
                                    totalValid++;
                                    if (std::abs(calculatedSteering - gsr.groundSteering()) <= THRESHOLD)
                                    {
                                        withinRange++;
                                    }
                                }
                                // Print output
                                if (totalValid > 0){
                                    acc = ((double)withinRange / totalValid) * 100.0;
                                }
                                std::cout << ts_ms << ";" << gsr.groundSteering() << ";" << calculatedSteering << ";" << acc << std::endl;
                                computedFile << calculatedSteering << "\n";
                                computedCurrent << ts_ms << "," << gsr.groundSteering() << "," << calculatedSteering << "\n";
                                hasAngle = false;
                            }
                        }
                    }
                }
            }
            // if datatype is GroundSteeringRequest (see: opendlv-standard-message-set)
            else if (envelope.dataType() == 1090)
            {
                ts = envelope.sampleTimeStamp();
                ts_ms = cluon::time::toMicroseconds(ts); // take timestamp
                
                // if corresponding image exists with timestamp
                gsr = cluon::extractMessage<opendlv::proxy::GroundSteeringRequest>(std::move(envelope));
                hasAngle = true;
            }
        }
    }
    computedFile.close();
    return 0;
}
