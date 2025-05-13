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

constexpr const bool AUTOREWIND{false};
constexpr const bool THREADING{false};

int32_t main(int32_t argc, char **argv) {
    auto commandlineArguments = cluon::getCommandlineArguments(argc, argv);

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

    cluon::Player player(recFile, AUTOREWIND, THREADING);


    std::cout << "Recording contains " << player.totalNumberOfEnvelopesInRecFile() << " messages" << std::endl;

    while (player.hasMoreData()) {
        auto next = player.getNextEnvelopeToBeReplayed();
        if (next.first) {
            cluon::data::Envelope envelope = next.second;
            
            if (verbose) {
                cluon::data::TimeStamp ts = envelope.sampleTimeStamp();
                int64_t ts_ms = cluon::time::toMicroseconds(ts);
                std::cout << "Received envelope with ID: " << envelope.dataType()
                          << " at " << ts_ms 
                          << std::endl;
            }
        }
    }

    std::cout << "Finished processing recording." << std::endl;
    return 0;
}