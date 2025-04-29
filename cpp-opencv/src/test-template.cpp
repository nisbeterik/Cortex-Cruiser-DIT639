#define CATCH_CONFIG_MAIN
#include "catch.hpp"
#include "istrue.hpp"

TEST_CASE("isTrue returns true", "[istrue]") {
    REQUIRE(isTrue() == true);
}