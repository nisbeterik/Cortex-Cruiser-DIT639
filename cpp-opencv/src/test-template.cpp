#define CATCH_CONFIG_MAIN
#include "catch.hpp"
#include "template-opencv.hpp"

TEST_CASE("isTrue returns true", "[template-opencv]") {
    REQUIRE(isTrue() == true);
}