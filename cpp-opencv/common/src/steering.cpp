#include "steering.hpp"

const cv::Scalar BLUE_LOWER(81, 102, 40);
const cv::Scalar BLUE_UPPER(148, 255, 123);
const cv::Scalar YELLOW_LOWER(16, 0, 123);
const cv::Scalar YELLOW_UPPER(90, 255, 255);

int OFFSET_X = 200;
int OFFSET_Y = 48;

double SCALE_FACTOR = 0.001;

namespace
{
    cv::Point lastBlueCentroid(-1, -1);
    cv::Point lastYellowCentroid(-1, -1);
}

cv::Point &getLastBlueCentroid() { return lastBlueCentroid; }
cv::Point &getLastYellowCentroid() { return lastYellowCentroid; }

void setLastBlueCentroid(const cv::Point &centroid)
{
    lastBlueCentroid = centroid;
}

void setLastYellowCentroid(const cv::Point &centroid)
{
    lastYellowCentroid = centroid;
}

cv::Mat createIgnoreMask(cv::Mat &image)
{
    // Create a blank mask of the same size as the image
    cv::Mat ignoreMask = cv::Mat::zeros(image.size(), CV_8UC1);
    // Define the polygon points for the bottom-middle region to ignore
    std::vector<cv::Point> bottomMiddlePoints = {
        cv::Point(image.cols / 3, image.rows * 2 / 3),     // Bottom-left of the mask
        cv::Point(image.cols * 2 / 3, image.rows * 2 / 3), // Bottom-right of the mask
        cv::Point(image.cols, image.rows),                 // Bottom-right corner
        cv::Point(0, image.rows)                           // Bottom-left corner
    };
    // Fill the bottom-middle polygon in the mask
    cv::fillPoly(ignoreMask, std::vector<std::vector<cv::Point>>{bottomMiddlePoints}, cv::Scalar(255));
    // Define the rectangle for the top 60% of the image
    cv::Rect topPart(0, 0, image.cols, image.rows * 0.55);
    // Fill the top part rectangle in the mask
    cv::rectangle(ignoreMask, topPart, cv::Scalar(255), -1);
    return ignoreMask;
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
    cv::bitwise_and(blueMask, ~ignoreMask, blueMask); // Apply mask to blue cones too
    cv::bitwise_and(yellowMask, ~ignoreMask, yellowMask);
   
    // Find contours for blue and yellow masks
    std::vector<std::vector<cv::Point>> blueContours, yellowContours;
    cv::findContours(blueMask, blueContours, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_SIMPLE);
    cv::findContours(yellowMask, yellowContours, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_SIMPLE);
   
    // Store all detected cone centroids
    std::vector<cv::Point> blueCentroids;
    std::vector<cv::Point> yellowCentroids;
   
    // Process blue contours to find centroids
    for (size_t i = 0; i < blueContours.size(); i++)
    {
        // Filter small contours that might be noise
        if (cv::contourArea(blueContours[i]) > 50)
        {
            cv::Moments m = cv::moments(blueContours[i]);
            if (m.m00 != 0)
            {
                cv::Point centroid(m.m10 / m.m00, m.m01 / m.m00);
                blueCentroids.push_back(centroid);
                cv::circle(img, centroid, 5, cv::Scalar(255, 0, 0), -1);
            }
        }
    }
    
    // Process yellow contours to find centroids
    for (size_t i = 0; i < yellowContours.size(); i++)
    {
        // Filter small contours that might be noise
        if (cv::contourArea(yellowContours[i]) > 50)
        {
            cv::Moments m = cv::moments(yellowContours[i]);
            if (m.m00 != 0)
            {
                cv::Point centroid(m.m10 / m.m00, m.m01 / m.m00);
                yellowCentroids.push_back(centroid);
                cv::circle(img, centroid, 5, cv::Scalar(0, 255, 255), -1);
            }
        }
    }
   
    // Default centroids if none are detected
    cv::Point blueCentroid = getLastBlueCentroid();
    cv::Point yellowCentroid = getLastYellowCentroid();
    
    // Update primary centroids if available
    if (!blueCentroids.empty())
    {
        // Use the lowest (closest) blue cone as primary
        blueCentroid = *std::min_element(blueCentroids.begin(), blueCentroids.end(),
                                         [](const cv::Point &a, const cv::Point &b)
                                         { return a.y > b.y; });
        setLastBlueCentroid(blueCentroid);
    }
    if (!yellowCentroids.empty())
    {
        // Use the lowest (closest) yellow cone as primary
        yellowCentroid = *std::min_element(yellowCentroids.begin(), yellowCentroids.end(),
                                           [](const cv::Point &a, const cv::Point &b)
                                           { return a.y > b.y; });
        setLastYellowCentroid(yellowCentroid);
    }
   
    // Fallback if no blue cones are visible
    if (blueCentroid.x == -1 && blueCentroid.y == -1)
    {
        cv::Point lastBlue = getLastBlueCentroid();
        if (lastBlue.x != -1 && lastBlue.y != -1)
        {
            blueCentroid = lastBlue;
        }
        else
        {
            blueCentroid = yellowCentroid + cv::Point(-OFFSET_X, OFFSET_Y);
        }
    }

    // Fallback if no yellow cones are visible
    if (yellowCentroid.x == -1 && yellowCentroid.y == -1)
    {
        cv::Point lastYellow = getLastYellowCentroid();
        if (lastYellow.x != -1 && lastYellow.y != -1)
        {
            yellowCentroid = lastYellow;
        }
        else
        {
            yellowCentroid = blueCentroid + cv::Point(OFFSET_X, OFFSET_Y);
        }
    }
    
    // Highlight the primary centroids used for steering
    cv::circle(img, blueCentroid, 8, cv::Scalar(255, 0, 0), 2);
    cv::circle(img, yellowCentroid, 8, cv::Scalar(0, 255, 255), 2);
   
    // Draw lines between centroids of the same color (rails)
    if (blueCentroids.size() > 1)
    {
        // Sort blue centroids by y-coordinate (bottom to top)
        std::sort(blueCentroids.begin(), blueCentroids.end(),
                  [](const cv::Point &a, const cv::Point &b)
                  { return a.y > b.y; });
        // Draw blue rail
        for (size_t i = 0; i < blueCentroids.size() - 1; i++)
        {
            cv::line(img, blueCentroids[i], blueCentroids[i + 1], cv::Scalar(255, 0, 0), 2);
        }
    }
    if (yellowCentroids.size() > 1)
    {
        // Sort yellow centroids by y-coordinate (bottom to top)
        std::sort(yellowCentroids.begin(), yellowCentroids.end(),
                  [](const cv::Point &a, const cv::Point &b)
                  { return a.y > b.y; });
        // Draw yellow rail
        for (size_t i = 0; i < yellowCentroids.size() - 1; i++)
        {
            cv::line(img, yellowCentroids[i], yellowCentroids[i + 1], cv::Scalar(0, 255, 255), 2);
        }
    }
    
    // Calculate path center points
    std::vector<cv::Point> pathCenterPoints;
    
    // Create center path if we have enough cones
    size_t numPoints = std::min(blueCentroids.size(), yellowCentroids.size());
    if (numPoints > 0)
    {
        // Ensure centroids are sorted by y-coordinate (distance from car)
        std::sort(blueCentroids.begin(), blueCentroids.end(),
                  [](const cv::Point &a, const cv::Point &b)
                  { return a.y > b.y; });
        std::sort(yellowCentroids.begin(), yellowCentroids.end(),
                  [](const cv::Point &a, const cv::Point &b)
                  { return a.y > b.y; });
        
                  // Create center points between corresponding blue and yellow cones
        for (size_t i = 0; i < numPoints; i++)
        {
            cv::Point center((blueCentroids[i].x + yellowCentroids[i].x) / 2,
                             (blueCentroids[i].y + yellowCentroids[i].y) / 2);
            pathCenterPoints.push_back(center);
            cv::circle(img, center, 3, cv::Scalar(0, 255, 0), -1);
        }

        // Draw the center path line
        if (pathCenterPoints.size() > 1)
        {
            for (size_t i = 0; i < pathCenterPoints.size() - 1; i++)
            {
                cv::line(img, pathCenterPoints[i], pathCenterPoints[i + 1], cv::Scalar(0, 255, 0), 2);
            }
        }
    }

    // Always calculate at least one path center point for steering
    cv::Point pathCenter;
    if (!pathCenterPoints.empty())
    {
        // Use the closest center point for steering (should be the first one after sorting)
        pathCenter = pathCenterPoints[0];
    }
    else
    {
        // Fallback to midpoint between primary centroids
        pathCenter = cv::Point((blueCentroid.x + yellowCentroid.x) / 2,
                               (blueCentroid.y + yellowCentroid.y) / 2);
    }
   
    // Highlight the main steering point
    cv::circle(img, pathCenter, 8, cv::Scalar(0, 255, 0), 2);
    
    // Calculate the steering angle
    int imageCenterX = img.cols / 2;
    double steeringAngle = (pathCenter.x - imageCenterX) * SCALE_FACTOR;
    
    // Draw a line from bottom center to path center (steering line)
    cv::Point bottomCenter(img.cols / 2, img.rows);
    cv::line(img, bottomCenter, pathCenter, cv::Scalar(0, 0, 255), 2);
    
    // Show processed images if verbose
    if (verbose)
    {
        cv::imshow("Processed Frame", img);
        cv::imshow("Blue Mask", blueMask);
        cv::imshow("Yellow Mask", yellowMask);
    }
    return -steeringAngle;
}