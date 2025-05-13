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

    cluon::Player player(recFile, cluon::data::Player::DISABLE_THREADING);

    std::cout << "Recording contains " << player.numberOfEnvelopes() << " messages" << std::endl;
    std::cout << "Duration: " << player.totalLength() << " seconds" << std::endl;

    while (player.hasMoreData()) {
        auto next = player.getNextEnvelopeToBeReplayed();
        if (next.first) {
            cluon::data::Envelope envelope = next.second;
            
            if (verbose) {
                std::cout << "Received envelope with ID: " << envelope.dataType() 
                          << " at " << envelope.sampleTimeStamp() << std::endl;
            }
            
        }
    }

    std::cout << "Finished processing recording." << std::endl;
    return 0;
}