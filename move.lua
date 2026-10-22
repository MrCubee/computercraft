os.loadAPI("obj.lua")

--------------
-- Position --
--------------

_POS_FILE = "position.data"
local originPoint = { x = 0, y = 0, z = 0, r = 0 }
local rpos = { x = 0, y = 0, z = 0, r = 0, lastPos = {} }

function loadSavedPos()
    local newPos = obj.loadObj(_POS_FILE)

    if not newPos or newPos.x == nil or newPos.y == nil or newPos.z == nil or newPos.r == nil then return false end
    rpos = newPos
    return true
end

local function positionEquals(pos1, pos2)
    return pos1 ~= nil and pos2 ~= nil and pos1.x == pos2.x and pos1.y == pos2.y and pos1.z == pos2.z
end

local function positionDifference(pos1, pos2)
    local dx = pos1.x - pos2.x
    local dy = pos1.y - pos2.y
    local dz = pos1.z - pos2.z

    if dx < 0 then dx = dx * -1 end
    if dy < 0 then dy = dy * -1 end
    if dz < 0 then dz = dz * -1 end
    return dx + dy + dz;
end

local function positionCopy(pos)
    if pos == nil or pos.x == nil or pos.y == nil or pos.z == nil then
        return nil
    end
    local posCopy = { x = pos.x, y = pos.y, z = pos.z }
    if pos.r ~= nil then
        posCopy.r = pos.r
    end
    return posCopy
end

local function copyPositionHistory()
    local historyCopy = {}
    for i = 1, #rpos.lastPos do
        historyCopy[i] = positionCopy(rpos.lastPos[i])
    end
    return historyCopy
end

local function clearHistory()
    rpos.lastPos = {}
    obj.saveObj(_POS_FILE, rpos)
end

local function historyIndexOfPosition(pos)
    if pos == nil or pos.x == nil or pos.y == nil or pos.z == nil then return nil end
    local total = #rpos.lastPos
    for i = 0, total - 1 do
        if positionEquals(pos, rpos.lastPos[total - i]) then return total - i end
    end
    return -1
end

local function getDistanceToComeBack()
    local prevPos = rpos
    local distance = 0
    local total = #rpos.lastPos

    if total < 1 then
        return math.abs(rpos.x) + math.abs(rpos.y) + math.abs(rpos.z)
    end
    for i = 0, total - 1 do
        local currentPos = rpos.lastPos[total - i]
        distance = distance + positionDifference(prevPos, currentPos)
        prevPos = currentPos
    end
    return distance + math.abs(prevPos.x) + math.abs(prevPos.y) + math.abs(prevPos.z)
end

local function pushToHistory(pos)
    if pos == nil then
        pos = rpos
    elseif pos.x == nil or pos.y == nil or pos.z == nil then
        return false
    elseif positionEquals(pos, originPoint) then
        return true
    end
    local index = #rpos.lastPos + 1
    rpos.lastPos[index] = { x = pos.x, y = pos.y, z = pos.z }
    return true
end

local function cleanHistory()
    local index = historyIndexOfPosition(rpos)
    if index < 0 then return end
    for i = index + 1, #rpos.lastPos do
        rpos.lastPos[i] = nil
    end
end

local function popFromHistory()
    local index = #rpos.lastPos
    if index < 1 then return nil end
    local pos = rpos.lastPos[index]
    rpos.lastPos[index] = nil
    return pos
end

---------------
-- Direction --
---------------

local moveMatrix = { [0] = { x = 1, z = 0 }, [1] = { x = 0, z = 1 }, [2] = { x = -1, z = 0 }, [3] = { x = 0, z = -1 } }

local function applyMatrix(op)
    if op == "add" then
        local matrix = moveMatrix[rpos.r]
        rpos.x = rpos.x + matrix.x
        rpos.z = rpos.z + matrix.z
    end
    if op == "sub" then
        local matrix = moveMatrix[rpos.r]
        rpos.x = rpos.x - matrix.x
        rpos.z = rpos.z - matrix.z
    end
end

------------
-- Action --
------------

historySaved = true

local function forward()
    if not turtle.native.forward() then
        return false
    end
    if historySaved == true then
        pushToHistory()
    end
    applyMatrix("add")
    cleanHistory()
    obj.saveObj(_POS_FILE, rpos)
    return true
end

local function back()
    if not turtle.native.back() then
        return false
    end
    if historySaved == true then
        pushToHistory()
    end
    applyMatrix("sub")
    cleanHistory()
    obj.saveObj(_POS_FILE, rpos)
    return true
end

local function turnLeft()
    if not turtle.native.turnLeft() then
        return false
    end
    rpos.r = rpos.r - 1
    if rpos.r < 0 then rpos.r = 3 end
    obj.saveObj(_POS_FILE, rpos)
    return true
end

local function turnRight()
    if not turtle.native.turnRight() then
        return false
    end
    rpos.r = rpos.r + 1
    if rpos.r > 3 then rpos.r = 0 end
    obj.saveObj(_POS_FILE, rpos)
    return true
end

local function up()
    if not turtle.native.up() then
        return false
    end
    if historySaved == true then
        pushToHistory()
    end
    rpos.y = rpos.y + 1
    cleanHistory()
    obj.saveObj(_POS_FILE, rpos)
    return true
end

local function down()
    if not turtle.native.down() then
        return false
    end
    if historySaved == true then
        pushToHistory()
    end
    rpos.y = rpos.y - 1
    cleanHistory()
    obj.saveObj(_POS_FILE, rpos)
    return true
end

--------------
-- Override --
--------------

local function callAction(func_action, count, func_before, func_after)
    if func_action == nil then
        return false
    end
    if count == nil then
        count = 1
    end
    for i = 1, count do
        local cancel = nil
        if func_before ~= nil then
            cancel = func_before(i)
        end
        if cancel ~= nil then
            return cancel
        end
        local result = func_action(i)
        if func_after ~= nil then
            cancel = func_after(i, result)
        end
        if cancel ~= nil then
            return cancel
        end
        if not result then
            return false
        end
    end
    return true
end

function turtle.forward(count, func_before, func_after)
    return callAction(forward, count, func_before, func_after)
end

function turtle.back(count, func_before, func_after)
    return callAction(back, count, func_before, func_after)
end

function turtle.up(count, func_before, func_after)
    return callAction(up, count, func_before, func_after)
end

function turtle.down(count, func_before, func_after)
    return callAction(down, count, func_before, func_after)
end

function turtle.turnLeft(count, func_before, func_after)
    return callAction(turnLeft, count, func_before, func_after)
end

function turtle.turnRight(count, func_before, func_after)
    return callAction(turnRight, count, func_before, func_after)
end

----------
-- Move --
----------

local function turn(r)
    while rpos.r ~= r do
        if rpos.r < r then
            if not turtle.turnRight() then
                return false
            end
        else
            if not turtle.turnLeft() then
                return false
            end
        end
    end
    return true
end

function turtle.goTo(target, func_before, func_after)
    while rpos.x ~= target.x or rpos.y ~= target.y or rpos.z ~= target.z or (target.r ~= nil and rpos.r ~= target.r) do
        local result = nil

        if func_before ~= nil then
            result = func_before()
            if result ~= nil then
                return result
            end
        end
        if rpos.x > target.x then
            if not turn(2) then return false end
            result = turtle.forward()
        elseif rpos.x < target.x then
            if not turn(0) then return false end
            result = turtle.forward()
        elseif rpos.z > target.z then
            if not turn(3) then return false end
            result = turtle.forward()
        elseif rpos.z < target.z then
            if not turn(1) then return false end
            result = turtle.forward()
        elseif rpos.y > target.y then
            result = turtle.down()
        elseif rpos.y < target.y then
            result = turtle.up()
        elseif rpos.r ~= nil then
            result = turn(target.r)
        end
        if func_after ~= nil then
            result = func_after(result)
            if result ~= nil then
                return result
            end
        end
        if not result then
            return false
        end
    end
    return true
end

function turtle.getPosition()
    return rpos.x, rpos.y, rpos.z, rpos.r
end

function turtle.getPositionHistory()
    return copyPositionHistory()
end

function turtle.pushToPositionHistory(pos)
    if pos == nil then return false end
    pushToHistory(pos)
    obj.saveObj(_POS_FILE, rpos)
end

function turtle.clearPositionHistory()
    clearHistory()
end

function turtle.removePositionHistory(count)
    if count == nil then
        count = 1
    end
    for i = 1, count do
        popFromHistory()
    end
end

function turtle.getDistanceToComeBack()
    return getDistanceToComeBack()
end

function turtle.comeBack(count, func_before, func_after)
    if count == nil then
        count = #rpos.lastPos
    end
    local prev = popFromHistory()
    local prevHistorySaved = historySaved
    historySaved = false
    while count > 0 and prev ~= nil do
        if not turtle.goTo(prev, func_before, func_after) then
            historySaved = true
            pushToHistory(prev)
            return false
        end
        prev = popFromHistory()
        count = count - 1;
    end
    if not turtle.goTo(originPoint, func_before, func_after) then return false end
    historySaved = prevHistorySaved
    return true
end
