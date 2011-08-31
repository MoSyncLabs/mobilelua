local a = A:new()
local b = a:GetB()
local t = {}
for i = 1, 100 do
  t[i] = a:GetB()
  assert(a:bounce(i)==i)
end

t = nil
b = nil
collectgarbage("collect")
assert(B.n == 0)
print("VarArg OK!")
