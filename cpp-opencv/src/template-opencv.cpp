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
#include <fstream>

// Include more libraries
#include <chrono>
#include <ctime>
#include <iostream>
#include <sstream>
#include <string>
#include <iomanip>
#include <deque>
#include <numeric>

// Declaration of method for processing image and calcualting steering
double processFrame(cv::Mat &img, bool verbose);

// GLOBAL VARIABLES

// HSV ranges for blue and yellow
const cv::Scalar BLUE_LOWER(81, 102, 40);
const cv::Scalar BLUE_UPPER(148, 255, 123);
const cv::Scalar YELLOW_LOWER(16, 0, 123);
const cv::Scalar YELLOW_UPPER(90, 255, 255);

// Adjust as needed
double SCALE_FACTOR = 0.0012; 
int OFFSET_X = 200;
int OFFSET_Y = 25; 

// Centroids for cones
static cv::Point lastBlueCentroid(-1, -1), lastYellowCentroid(-1, -1);

// Track width tracking
std::deque<double> trackWidthHistory;
const size_t MAX_HISTORY = 10;

// Steering smoothing
double previousSteeringAngle = 0.0;

// Utility function to calculate average track width
double averageTrackWidth(const std::deque<double>& widths) {
    if (widths.empty()) return 350.0; // Default width
    return std::accumulate(widths.begin(), widths.end(), 0.0) / widths.size();
}

// Dynamic scaling factor based on cone distance
double getScalingFactor(const cv::Point& pathCenter, int imageHeight) {
    // Closer cones (higher Y value) = more aggressive steering
    double baseScale = 0.0012;
    double distanceFactor = 1.0 + ((imageHeight - pathCenter.y) / (double)imageHeight);
    return baseScale * distanceFactor;
}

int32_t main(int32_t argc, char **argv)
{
    int32_t retCode{1};
    // Parse the command line parameters as we require the user to specify some mandatory information on startup.
    std::ofstream computedFile("/host/computed_output.csv");

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
            // Open output file for computed steering angle
            computedFile << "timestamp,groundSteering,groundTruth\n"; // Write CSV header
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
                // std::cout << "lambda: groundSteering = " << gsr.groundSteering() << std::endl;
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
                std::cout << "group_06;" << ts_ms << ";" << -steeringAngle << std::endl;

                // If you want to access the latest received ground steering, don't forget to lock the mutex:
                {
                    std::lock_guard<std::mutex> lck(gsrMutex);
                    computedFile << ts_ms << "," << -steeringAngle << "," << gsr.groundSteering() << "\n";
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
    computedFile.close();
    return retCode;
}

cv::Mat createIgnoreMask(cv::Mat &image)
{
    // Create a blank mask of the same size as the image
    cv::Mat ignoreMask = cv::Mat::zeros(image.size(), CV_8UC1);

    // Define the polygon points for the bottom-middle region to ignore
    std::vector<cv::Point> bottomMiddlePoints = {
        cv::Point(image.cols * 0.4, image.rows * 3 / 4),  // Bottom-left of the mask
        cv::Point(image.cols * 0.6, image.rows * 3 / 4),  // Bottom-right of the mask
        cv::Point(image.cols, image.rows),                 // Bottom-right corner
        cv::Point(0, image.rows)                           // Bottom-left corner
    };

    // Fill the bottom-middle polygon in the mask
    cv::fillPoly(ignoreMask, std::vector<std::vector<cv::Point>>{bottomMiddlePoints}, cv::Scalar(255));

    // Define the rectangle for the top portion of the image 
    cv::Rect topPart(0, 0, image.cols, image.rows * 0.4); // 40%

    // Fill the top part rectangle in the mask
    cv::rectangle(ignoreMask, topPart, cv::Scalar(255), -1);

    return ignoreMask;
}

// Get lookahead point for path prediction
cv::Point getLookaheadPoint(const std::vector<cv::Point>& pathCenterPoints) {
    if (pathCenterPoints.size() > 2) {
        // Use a point further ahead on the path
        return pathCenterPoints[std::min(2, (int)pathCenterPoints.size()-1)];
    }
    return pathCenterPoints.empty() ? cv::Point(-1, -1) : pathCenterPoints[0]; // fallback to closest
}

// Get weighted path centers
std::vector<cv::Point> getWeightedPathCenters(const std::vector<cv::Point>& blues, 
                                             const std::vector<cv::Point>& yellows) {
    std::vector<cv::Point> centers;
    
    // Simple pairing: match by Y values (closest distance)
    for (const auto& blue : blues) {
        // Find closest yellow cone by vertical position
        cv::Point closestYellow(-1, -1);
        double minDist = std::numeric_limits<double>::max();
        
        for (const auto& yellow : yellows) {
            double dist = std::abs(blue.y - yellow.y);
            if (dist < minDist) {
                minDist = dist;
                closestYellow = yellow;
            }
        }
        
        // If found a reasonable match
        if (closestYellow.x != -1 && minDist < 100) {
            cv::Point center((blue.x + closestYellow.x) / 2, 
                          (blue.y + closestYellow.y) / 2);
            centers.push_back(center);
        }
    }
    
    // Sort by y-coordinate (distance)
    std::sort(centers.begin(), centers.end(), 
        [](const cv::Point& a, const cv::Point& b) { return a.y > b.y; });
        
    return centers;
}

double processFrame(cv::Mat &img, bool verbose)
{
    // Convert the image to HSV color space
    cv::Mat hsvImage;
    cv::cvtColor(img, hsvImage, cv::COLOR_BGR2HSV);

    // Detect blue and yellow areas
    cv::Mat blueMask, yellowMask;
    cv::inRange(hsvImage, BLUE_LOWER, BLUE_UPPER, blueMask);
    cv::inRange(hsvImage, YELLOW_LOWER, YELLOW_UPPER, yellowMask);

    // Create and apply the ignore mask
    cv::Mat ignoreMask = createIgnoreMask(img);
    cv::bitwise_and(blueMask, ~ignoreMask, blueMask); 
    cv::bitwise_and(yellowMask, ~ignoreMask, yellowMask);

    // Find contours for blue and yellow masks
    std::vector<std::vector<cv::Point>> blueContours, yellowContours;
    cv::findContours(blueMask, blueContours, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_SIMPLE);
    cv::findContours(yellowMask, yellowContours, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_SIMPLE);

    // Store all detected cone centroids
    std::vector<cv::Point> blueCentroids;
    std::vector<cv::Point> yellowCentroids;
    
    // Process blue contours to find centroids
    for (size_t i = 0; i < blueContours.size(); i++) {
        // Filter small contours that might be noise
        if (cv::contourArea(blueContours[i]) > 50) {
            cv::Moments m = cv::moments(blueContours[i]);
            if (m.m00 != 0) {
                cv::Point centroid(m.m10 / m.m00, m.m01 / m.m00);
                blueCentroids.push_back(centroid);
                cv::circle(img, centroid, 5, cv::Scalar(255, 0, 0), -1);
            }
        }
    }
    
    // Process yellow contours to find centroids
    for (size_t i = 0; i < yellowContours.size(); i++) {
        // Filter small contours that might be noise
        if (cv::contourArea(yellowContours[i]) > 50) {
            cv::Moments m = cv::moments(yellowContours[i]);
            if (m.m00 != 0) {
                cv::Point centroid(m.m10 / m.m00, m.m01 / m.m00);
                yellowCentroids.push_back(centroid);
                cv::circle(img, centroid, 5, cv::Scalar(0, 255, 255), -1);
            }
        }
    }
    
    // Default centroids if none are detected
    cv::Point blueCentroid = lastBlueCentroid;
    cv::Point yellowCentroid = lastYellowCentroid;
    
    // Update primary centroids if available
    if (!blueCentroids.empty()) {
        // Use the closest blue cone as primary
        blueCentroid = *std::min_element(blueCentroids.begin(), blueCentroids.end(), 
            [](const cv::Point& a, const cv::Point& b) { return a.y > b.y; });
        lastBlueCentroid = blueCentroid;
    }
    
    if (!yellowCentroids.empty()) {
        // Use the closest yellow cone as primary
        yellowCentroid = *std::min_element(yellowCentroids.begin(), yellowCentroids.end(), 
            [](const cv::Point& a, const cv::Point& b) { return a.y > b.y; });
        lastYellowCentroid = yellowCentroid;
    }

    // Track width calculation
    if (blueCentroid.x != -1 && yellowCentroid.x != -1) {
        double currentWidth = abs(yellowCentroid.x - blueCentroid.x);
        trackWidthHistory.push_back(currentWidth);
        if (trackWidthHistory.size() > MAX_HISTORY) {
            trackWidthHistory.pop_front();
        }
    }

    // Enhanced fallback when cones are missing
    if (blueCentroid.x == -1 && yellowCentroid.x != -1) {
        // Yellow visible but blue missing -> use track width estimate
        double estimatedTrackWidth = averageTrackWidth(trackWidthHistory);
        blueCentroid = yellowCentroid + cv::Point(-estimatedTrackWidth, 0);
        lastBlueCentroid = blueCentroid;
    } else if (yellowCentroid.x == -1 && blueCentroid.x != -1) {
        // Blue visible but yellow missing -> use track width estimate
        double estimatedTrackWidth = averageTrackWidth(trackWidthHistory);
        yellowCentroid = blueCentroid + cv::Point(estimatedTrackWidth, 0);
        lastYellowCentroid = yellowCentroid;
    } else if (blueCentroid.x == -1 && yellowCentroid.x == -1) {
        // Both missing, use last known positions with offsets
        if (lastBlueCentroid.x != -1 && lastYellowCentroid.x == -1) {
            // Only blue was known previously
            double estimatedTrackWidth = averageTrackWidth(trackWidthHistory);
            yellowCentroid = lastBlueCentroid + cv::Point(estimatedTrackWidth, 0);
        } else if (lastBlueCentroid.x == -1 && lastYellowCentroid.x != -1) {
            // Only yellow was known previously
            double estimatedTrackWidth = averageTrackWidth(trackWidthHistory);
            blueCentroid = lastYellowCentroid + cv::Point(-estimatedTrackWidth, 0);
        } else if (lastBlueCentroid.x == -1 && lastYellowCentroid.x == -1) {
            // No previous knowledge, use default positions
            blueCentroid = cv::Point(img.cols / 2 - OFFSET_X, img.rows * 0.7);
            yellowCentroid = cv::Point(img.cols / 2 + OFFSET_X, img.rows * 0.7);
        }
    }

    // Highlight the primary centroids used for steering
    cv::circle(img, blueCentroid, 8, cv::Scalar(255, 0, 0), 2);
    cv::circle(img, yellowCentroid, 8, cv::Scalar(0, 255, 255), 2);

    // Draw lines between centroids of the same color (rails)
    if (blueCentroids.size() > 1) {
        // Sort blue centroids by y-coordinate (bottom to top)
        std::sort(blueCentroids.begin(), blueCentroids.end(), 
            [](const cv::Point& a, const cv::Point& b) { return a.y > b.y; });
        
        // Draw blue rail
        for (size_t i = 0; i < blueCentroids.size() - 1; i++) {
            cv::line(img, blueCentroids[i], blueCentroids[i+1], cv::Scalar(255, 0, 0), 2);
        }
    }
    
    if (yellowCentroids.size() > 1) {
        // Sort yellow centroids by y-coordinate (bottom to top)
        std::sort(yellowCentroids.begin(), yellowCentroids.end(), 
            [](const cv::Point& a, const cv::Point& b) { return a.y > b.y; });
        
        // Draw yellow rail
        for (size_t i = 0; i < yellowCentroids.size() - 1; i++) {
            cv::line(img, yellowCentroids[i], yellowCentroids[i+1], cv::Scalar(0, 255, 255), 2);
        }
    }

    // Get weighted path centers for better path estimation
    std::vector<cv::Point> pathCenterPoints = getWeightedPathCenters(blueCentroids, yellowCentroids);
    
    // If we don't have weighted path centers, fall back to basic calculation
    if (pathCenterPoints.empty()) {
        // Create center path if we have enough cones
        size_t numPoints = std::min(blueCentroids.size(), yellowCentroids.size());
        if (numPoints > 0) {
            // Ensure centroids are sorted by y-coordinate (distance from car)
            std::sort(blueCentroids.begin(), blueCentroids.end(), 
                [](const cv::Point& a, const cv::Point& b) { return a.y > b.y; });
            std::sort(yellowCentroids.begin(), yellowCentroids.end(), 
                [](const cv::Point& a, const cv::Point& b) { return a.y > b.y; });
            
            // Create center points between corresponding blue and yellow cones
            for (size_t i = 0; i < numPoints; i++) {
                cv::Point center((blueCentroids[i].x + yellowCentroids[i].x) / 2, 
                                (blueCentroids[i].y + yellowCentroids[i].y) / 2);
                pathCenterPoints.push_back(center);
                cv::circle(img, center, 3, cv::Scalar(0, 255, 0), -1);
            }
        }
    }
    
    // Draw the center path line
    if (pathCenterPoints.size() > 1) {
        for (size_t i = 0; i < pathCenterPoints.size() - 1; i++) {
            cv::line(img, pathCenterPoints[i], pathCenterPoints[i+1], cv::Scalar(0, 255, 0), 2);
        }
    }
    
    // Always calculate at least one path center point for steering
    cv::Point pathCenter;
    if (!pathCenterPoints.empty()) {
        // Use the closest center point for steering 
        pathCenter = pathCenterPoints[0];
    } else {
        // Fallback to midpoint between primary centroids
        pathCenter = cv::Point((blueCentroid.x + yellowCentroid.x) / 2, 
                            (blueCentroid.y + yellowCentroid.y) / 2);
    }
    
    // Get lookahead point for path prediction
    cv::Point lookaheadPoint = getLookaheadPoint(pathCenterPoints);
    if (lookaheadPoint.x != -1) {
        // If we have a valid lookahead point, blend it with immediate point
        pathCenter.x = pathCenter.x * 0.7 + lookaheadPoint.x * 0.3;
        pathCenter.y = pathCenter.y * 0.7 + lookaheadPoint.y * 0.3;
        // Mark the lookahead point
        cv::circle(img, lookaheadPoint, 6, cv::Scalar(0, 200, 0), 2);
    }
    
    // Highlight the main steering point
    cv::circle(img, pathCenter, 8, cv::Scalar(0, 255, 0), 2);

    // Draw a line from bottom center to path center (steering line)
    cv::Point bottomCenter(img.cols / 2, img.rows);
    cv::line(img, bottomCenter, pathCenter, cv::Scalar(0, 0, 255), 2);

    // Calculate the steering angle with dynamic scaling
    int imageCenterX = img.cols / 2;
    double rawSteeringAngle = (pathCenter.x - imageCenterX) * getScalingFactor(pathCenter, img.rows);
    
    // Apply steering smoothing
    double smoothedSteeringAngle = previousSteeringAngle * 0.3 + rawSteeringAngle * 0.7;
    previousSteeringAngle = smoothedSteeringAngle;

    // Show processed images if verbose
    if (verbose) {
        cv::imshow("Processed Frame", img);
        cv::imshow("Blue Mask", blueMask);
        cv::imshow("Yellow Mask", yellowMask);
        
        // Display steering info
        std::string steerInfo = "Steering: " + std::to_string(smoothedSteeringAngle);
        cv::putText(img, steerInfo, cv::Point(10, 60), cv::FONT_HERSHEY_SIMPLEX, 0.5, cv::Scalar(255, 255, 255), 1);
    }

    return smoothedSteeringAngle;
}