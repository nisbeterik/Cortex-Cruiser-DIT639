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


// booleans for Player parameters
constexpr const bool AUTOREWIND{false};
constexpr const bool THREADING{false};

int32_t main(int32_t argc, char **argv) {
    auto commandlineArguments = cluon::getCommandlineArguments(argc, argv);

    // parse recording file path in arguments and --verbose flag
    if (commandlineArguments.count("rec") == 0) {
        std::cerr << argv[0] << " requires a recording file to process." << std::endl;
        std::cerr << "Usage:   " << argv[0] << " --rec=<Recording.rec> [--verbose]" << std::endl;
        std::cerr << "Example: " << argv[0] << " --rec=myRecording.rec" << std::endl;
        return 1;
    }

    const std::string recFile = commandlineArguments["rec"]; 
    bool verbose = (commandlineArguments.count("verbose") != 0);

    if (verbose) {
        std::cout << "Processing recording file: " << recFile << std::endl;
    }

    cluon::Player player(recFile, AUTOREWIND, THREADING); // pass recording file and other parameters to Player object


    opendlv::proxy::GroundSteeringRequest gsr; // variable to store gsr message
    opendlv::proxy::ImageReading ir; // variable to store imagereading message
    cluon::data::TimeStamp ts; // TimeStamp object to store timestamp
    int64_t ts_ms; // variable to store timestamp in millieseconds
    int32_t lineCount = 0; // line count to make the number of prints matches number of groundsteering messages
    bool hasImage = false; // variable to keep track if image frame has equivalent gsr data
    cv::Mat image;

    // loop that ends when .rec file has no more data

    while (player.hasMoreData()) {
        auto next = player.getNextEnvelopeToBeReplayed(); // get next envelope of .rec file
        if (next.first) {
            cluon::data::Envelope envelope = next.second; // store current envelope
            
            if (verbose) {

                // if datatype is ImageReading (see opendlv-standard-message-set)
                if(envelope.dataType() == 1055) {
                    ts = envelope.sampleTimeStamp();
                    ts_ms = cluon::time::toMicroseconds(ts); // take timestamp
                    ir = cluon::extractMessage<opendlv::proxy::ImageReading>(std::move(envelope));
                    cv::Mat wrapped(ir.height(), ir.width(), CV_8UC4, ir.data()); // extract message into ir var
                    image = wrapped.clone();
                    if(!image.empty()) {
                        std::cout << "success" << std::endl;
                    }
                    hasImage = true;
                } else if (envelope.dataType() == 1090) { // if datatype is GroundSteeringRequest (see: opendlv-standard-message-set)
                    // if corresponding image exists with timestamp
                    if(hasImage) {
                        gsr = cluon::extractMessage<opendlv::proxy::GroundSteeringRequest>(std::move(envelope));
                        std::cout << "group_06;" << ts_ms << ";" << gsr.groundSteering() << ";" << ir.width() << std::endl;
                        lineCount++;
                        hasImage = false;
                    }
                }
            }
        }
    }

    std::cout << "Linecount = " << lineCount << std::endl;
    return 0;
}

