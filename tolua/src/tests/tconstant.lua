dofile("myassert.lua")

assert(FIRST==M.FIRST)
assert(FIRST==A.FIRST)
assert(SECOND==M.SECOND)
assert(SECOND==A.SECOND)
assert(THIRD==M.THIRD)
assert(THIRD==A.THIRD)

assert(ONE==M.ONE)
assert(ONE==A.ONE)
assert(TWO==M.TWO)
assert(TWO==A.TWO)

print("Constant test OK")
