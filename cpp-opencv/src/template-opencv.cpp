/*
 * Copyright (C) 2020  Christian Berger
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

// Include the single-file, header-only middleware libcluon to create high-performance microservices
#include "cluon-complete.hpp"
// Include the OpenDLV Standard Message Set that contains messages that are usually exchanged for automotive or robotic applications
#include "opendlv-standard-message-set.hpp"
// Include the GUI and image processing header files from OpenCV
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>

// Include more libraries
#include <chrono>
#include <ctime>
#include <iostream>
#include <sstream>
#include <string>
#include <iomanip>

// Declaration of method for processing image and calcualting steering
double processFrame(cv::Mat &img, bool verbose);

// GLOBAL VARIABLES

// HSV ranges for blue and yellow (change values later)
const cv::Scalar BLUE_LOWER(100, 50, 30);
const cv::Scalar BLUE_UPPER(120, 255, 253);
const cv::Scalar YELLOW_LOWER(16, 0, 0);
const cv::Scalar YELLOW_UPPER(90, 255, 255);

double SCALE_FACTOR = 0.001; // Adjust as needed

int32_t main(int32_t argc, char **argv)
{
    int32_t retCode{1};
    // Parse the command line parameters as we require the user to specify some mandatory information on startup.
    auto commandlineArguments = cluon::getCommandlineArguments(argc, argv);
    if ((0 == commandlineArguments.count("cid")) ||
        (0 == commandlineArguments.count("name")) ||
        (0 == commandlineArguments.count("width")) ||
        (0 == commandlineArguments.count("height")))
    {
        std::cerr << argv[0] << " attaches to a shared memory area containing an ARGB image." << std::endl;
        std::cerr << "Usage:   " << argv[0] << " --cid=<OD4 session> --name=<name of shared memory area> [--verbose]" << std::endl;
        std::cerr << "         --cid:    CID of the OD4Session to send and receive messages" << std::endl;
        std::cerr << "         --name:   name of the shared memory area to attach" << std::endl;
        std::cerr << "         --width:  width of the frame" << std::endl;
        std::cerr << "         --height: height of the frame" << std::endl;
        std::cerr << "Example: " << argv[0] << " --cid=253 --name=img --width=640 --height=480 --verbose" << std::endl;
    }
    else
    {
        // Extract the values from the command line parameters
        const std::string NAME{commandlineArguments["name"]};
        const uint32_t WIDTH{static_cast<uint32_t>(std::stoi(commandlineArguments["width"]))};
        const uint32_t HEIGHT{static_cast<uint32_t>(std::stoi(commandlineArguments["height"]))};
        const bool VERBOSE{commandlineArguments.count("verbose") != 0};

        // Attach to the shared memory.
        std::unique_ptr<cluon::SharedMemory> sharedMemory{new cluon::SharedMemory{NAME}};
        if (sharedMemory && sharedMemory->valid())
        {
            std::clog << argv[0] << ": Attached to shared memory '" << sharedMemory->name() << " (" << sharedMemory->size() << " bytes)." << std::endl;

            // Interface to a running OpenDaVINCI session where network messages are exchanged.
            // The instance od4 allows you to send and receive messages.
            cluon::OD4Session od4{static_cast<uint16_t>(std::stoi(commandlineArguments["cid"]))};

            opendlv::proxy::GroundSteeringRequest gsr;
            std::mutex gsrMutex;
            auto onGroundSteeringRequest = [&gsr, &gsrMutex](cluon::data::Envelope &&env)
            {
                // The envelope data structure provide further details, such as sampleTimePoint as shown in this test case:
                // https://github.com/chrberger/libcluon/blob/master/libcluon/testsuites/TestEnvelopeConverter.cpp#L31-L40
                std::lock_guard<std::mutex> lck(gsrMutex);
                gsr = cluon::extractMessage<opendlv::proxy::GroundSteeringRequest>(std::move(env));
                std::cout << "lambda: groundSteering = " << gsr.groundSteering() << std::endl;
            };

            od4.dataTrigger(opendlv::proxy::GroundSteeringRequest::ID(), onGroundSteeringRequest);

            // Endless loop; end the program by pressing Ctrl-C.
            while (od4.isRunning())
            {
                // OpenCV data structure to hold an image.
                cv::Mat img;

                // Wait for a notification of a new frame.
                sharedMemory->wait();

                // Lock the shared memory.
                sharedMemory->lock();
                {
                    // Copy the pixels from the shared memory into our own data structure.
                    cv::Mat wrapped(HEIGHT, WIDTH, CV_8UC4, sharedMemory->data());
                    img = wrapped.clone();
                }

                auto [isValid, ts] = sharedMemory->getTimeStamp();
                sharedMemory->unlock();

                // Convert to ms
                int64_t ts_ms = cluon::time::toMicroseconds(ts);

                // Get current time
                cluon::data::TimeStamp now = cluon::time::now();

                // Extract seconds and microseconds from now-TimeStamp
                uint64_t seconds = now.seconds();
                std::time_t time = static_cast<std::time_t>(seconds);

                // Convert current time to UTC
                std::tm *utc_time = std::gmtime(&time);
                std::ostringstream utc_time_stream;
                utc_time_stream << std::put_time(utc_time, "%Y-%m-%dT%H:%M:%SZ");

                // Construct the final string
                std::string name = "Group 06";
                std::ostringstream final_stream;
                final_stream << "Now: " << utc_time_stream.str()
                             << "; ts: " << ts_ms
                             << "; " << name;

                std::string final_string = final_stream.str();

                // Create text
                cv::Point text_position(10, 30);
                int font_face = cv::FONT_HERSHEY_SIMPLEX;
                double font_scale = 0.5;
                int thickness = 1;
                cv::Scalar text_color(255, 255, 255);

                // Overlay the text on the frame
                cv::putText(img, final_string, text_position, font_face, font_scale, text_color, thickness);

                // Pass the frame to the helper function for processing
                double steeringAngle = processFrame(img, VERBOSE);
                std::string direction = (steeringAngle > 0) ? "left" : "right";
                std::cout << "group_06; " << ts_ms << "; " << steeringAngle << direction << std::endl;

                // If you want to access the latest received ground steering, don't forget to lock the mutex:
                {
                    std::lock_guard<std::mutex> lck(gsrMutex);
                    std::cout << "main: groundSteering = " << gsr.groundSteering() << "ts: " << ts_ms << std::endl;
                }

                // Display image on your screen.
                if (VERBOSE)
                {
                    cv::imshow(sharedMemory->name().c_str(), img);
                    cv::waitKey(1);
                }
            }
        }
        retCode = 0;
    }
    return retCode;
}

cv::Mat createIgnoreMask(cv::Mat &image)
{
    // Create a blank mask of the same size as the image
    cv::Mat ignoreMask = cv::Mat::zeros(image.size(), CV_8UC1);

    // Define the polygon points for the region to ignore (center-bottom part)
    std::vector<cv::Point> points = {
        cv::Point(image.cols / 3, image.rows * 2 / 3),     // Bottom-left of the mask
        cv::Point(image.cols * 2 / 3, image.rows * 2 / 3), // Bottom-right of the mask
        cv::Point(image.cols, image.rows),                 // Bottom-right corner
        cv::Point(0, image.rows)                           // Bottom-left corner
    };

    // Fill the polygon in the mask
    cv::fillPoly(ignoreMask, std::vector<std::vector<cv::Point>>{points}, cv::Scalar(255));

    return ignoreMask;
}

double processFrame(cv::Mat &img, bool verbose) {
    // Convert the image to HSV color space
    cv::Mat hsvImage;
    cv::cvtColor(img, hsvImage, cv::COLOR_BGR2HSV);

    // Detect blue and yellow areas
    cv::Mat blueMask, yellowMask;
    cv::inRange(hsvImage, BLUE_LOWER, BLUE_UPPER, blueMask);
    cv::inRange(hsvImage, YELLOW_LOWER, YELLOW_UPPER, yellowMask);

    // Create and apply the ignore mask
    cv::Mat ignoreMask = createIgnoreMask(img);
    cv::bitwise_and(yellowMask, ~ignoreMask, yellowMask);

    // Find contours for blue and yellow masks
    std::vector<std::vector<cv::Point>> blueContours, yellowContours;
    cv::findContours(blueMask, blueContours, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_SIMPLE);
    cv::findContours(yellowMask, yellowContours, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_SIMPLE);

    // Find the centroids of the blue and yellow contours
    cv::Point blueCentroid(0, 0), yellowCentroid(0, 0);
    if (!blueContours.empty()) {
        cv::Moments m = cv::moments(blueContours[0]);
        if (m.m00 != 0) {
            blueCentroid = cv::Point(m.m10 / m.m00, m.m01 / m.m00);
        }
    }
    if (!yellowContours.empty()) {
        cv::Moments m = cv::moments(yellowContours[0]);
        if (m.m00 != 0) {
            yellowCentroid = cv::Point(m.m10 / m.m00, m.m01 / m.m00);
        }
    }

    // Draw centroids and path center
    cv::circle(img, blueCentroid, 5, cv::Scalar(255, 0, 0), -1);
    cv::circle(img, yellowCentroid, 5, cv::Scalar(0, 255, 255), -1);

    cv::Point pathCenter((blueCentroid.x + yellowCentroid.x) / 2, (blueCentroid.y + yellowCentroid.y) / 2);
    cv::circle(img, pathCenter, 5, cv::Scalar(0, 255, 0), -1);

    // Calculate the steering angle
    int imageCenterX = img.cols / 2;
    double steeringAngle = (pathCenter.x - imageCenterX) * SCALE_FACTOR;

    // Show processed images if verbose
    if (verbose) {
        cv::imshow("Processed Frame", img);
        cv::imshow("Blue Mask", blueMask);
        cv::imshow("Yellow Mask", yellowMask);
    }

    return steeringAngle;
}
