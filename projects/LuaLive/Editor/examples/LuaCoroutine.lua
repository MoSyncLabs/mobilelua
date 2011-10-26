local function test()
  print("Start 1")
  error("Ouch")
  for i = 1, 3 do
    print("Loop " .. i)
  end
  print("End 1")
end

local coro_debugee = coroutine.create(test)
print("Resuming test()")
coroutine.resume(coro_debugee)
print("Done")
print("---")