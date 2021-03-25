#include <lib_A/lib_A.hpp>
#include <lib_B/lib_B.hpp>

#include <tool_1/fn.hpp>

namespace tool_1 {

int fn()
{
    auto answer = (lib_A::fn_a() + lib_B::fn_b()) / 2;
    return answer;
}

} // namespace tool_1