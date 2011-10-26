
EventMonitor:OnSensor(function(sensor, x, y, z)
  log(sensor .. " " .. x .. " " .. y .. " " .. z)
end)

for i = 1, 100 do
  for sensor = 1, 5 do
    maSensorStart(sensor, -2)
  end
  for sensor = 1, 5 do
    maSensorStop(sensor)
  end
end

for i = 1, 100 do
  for sensor = 1, 5 do
    maSensorStart(sensor, -2)
  end
end

for i = 1, 100 do
  for sensor = 1, 5 do
    maSensorStop(sensor)
  end
end
