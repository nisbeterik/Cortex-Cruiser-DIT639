#ifndef STEERING_H
#define STEERING_H

#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>

extern int OFFSET_X;
extern int OFFSET_Y;

extern const cv::Scalar BLUE_LOWER, BLUE_UPPER, YELLOW_LOWER, YELLOW_UPPER;

extern double SCALE_FACTOR;

extern cv::Point& getLastBlueCentroid();
extern cv::Point& getLastYellowCentroid();
void setLastBlueCentroid(const cv::Point& centroid);
void setLastYellowCentroid(const cv::Point& centroid);

extern double processFrame(cv::Mat &img, bool verbose);
extern cv::Mat createIgnoreMask(cv::Mat &image);

#endif
