--[[
  Moves job from active to delayed set.

  Input: 
    KEYS[1] active key
    KEYS[2] delayed key
    KEYS[3] job key

    ARGV[1] delayedTimestamp
    ARGV[2] the id of the job
    ARGV[3] queue token
    ARGV[4] should update job error data (with args 5-7)
    ARGV[5]  |- attemptsMade
    ARGV[6]  |- stacktrace
    ARGV[7]  |- failedReason

  Output:
    0 - OK
   -1 - Missing job.
   -2 - Job is locked.

  Events:
    - delayed key.
]]
local rcall = redis.call

if rcall("EXISTS", KEYS[3]) == 1 then
  -- Update job data if desired.
  if ARGV[4] == "1" then
    rcall("HMSET", KEYS[3], "attemptsMade", ARGV[5], "stacktrace", ARGV[6], "failedReason", ARGV[7])
  end

  -- Check for job lock
  if ARGV[3] ~= "0" then
    local lockKey = KEYS[3] .. ':lock'
    local lock = rcall("GET", lockKey)
    if rcall("GET", lockKey) ~= ARGV[3] then
      return -2
    end
  end
  
  local score = tonumber(ARGV[1])
  rcall("ZADD", KEYS[2], score, ARGV[2])
  rcall("PUBLISH", KEYS[2], (score / 0x1000))
  rcall("LREM", KEYS[1], 0, ARGV[2])

  return 0
else
  return -1
end
