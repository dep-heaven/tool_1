#include <catch2/catch.hpp>

#include <tool_1/fn.hpp>

TEST_CASE("Some demo test", "[demo]")
{
    // We need to get the answer to all of our questions
    REQUIRE(42 == tool_1::fn());
}