os.loadAPI("obj.lua")
os.loadAPI("move.lua")

_EXCAVATE_FILE = "excavate.data"
local excavate = obj.loadObj(_EXCAVATE_FILE)
local inventory = {}
local args = {...}

local function isLiquid(func_inspect)
    local present, block = func_inspect()

    if present and (block.name == "minecraft:water" or block.name == "minecraft:lava") then
        return true
    end
    return false
end

local function inventoryGetSpace()
    local space = 0

    for i = 1, 16 do
        turtle.select(i)
        if turtle.getItemDetail() == nil then
            space = space + 1
        end
    end
    turtle.select(1)
    return space
end

local function needToComeBack()
    if excavate.needFuel == true or excavate.needPlace == true then return true end
    if turtle.getDistanceToComeBack() + 3 >= turtle.getFuelLevel() then
        excavate.needFuel = true
        obj.saveObj(_EXCAVATE_FILE, excavate)
    end
    inventory.space = inventoryGetSpace()
    if inventory.space ~= nil and inventory.space < 3 then
        excavate.needPlace = true
        obj.saveObj(_EXCAVATE_FILE, excavate)
    end
    return excavate.needFuel == true or excavate.needPlace == true
end

local function proceedRefuel()
    local count
    while excavate.position.x + math.abs(excavate.position.y) + excavate.position.z + 256 > turtle.getFuelLevel() do
        print("Need more fuel ! Press Enter to continue after put fuel...")
        read()
        for i = 1, 16 do
            turtle.select(i)
            count = turtle.getItemCount(i)
            if count > 0 then turtle.refuel(count) end
        end
        turtle.select(1)
    end
    if excavate.needFuel ~= nil then
        excavate.needFuel = nil
        obj.saveObj(_EXCAVATE_FILE, excavate)
    end
end

local function proceedDropAll()
    for i = 1, 16 do
        turtle.select(i)
        turtle.drop()
    end
    turtle.select(1)
    inventory.space = 0
    if excavate.needPlace ~= nil then
        excavate.needPlace = nil
        obj.saveObj(_EXCAVATE_FILE, excavate)
    end
end

local function proceedReload()
    if excavate.position == nil then
        local currentX, currentY, currentZ, currentRotate = turtle.getPosition()
        excavate.position = {x = currentX, y = currentY, z = currentZ, r = currentRotate}
        obj.saveObj(_EXCAVATE_FILE, excavate)
    end
    if excavate.needFuel == true or excavate.needPlace == true then
        deepComeBack()
        turtle.turnLeft(2)
        proceedDropAll()
        proceedRefuel()
    end
    if not turtle.goTo(excavate.position) then
        turtle.comeBack()
        return false
    end
    excavate.position = nil
    obj.saveObj(_EXCAVATE_FILE, excavate)
    return true
end

local function dig(digFront)
    turtle.digUp()
    turtle.digDown()
    if digFront == true then
        while turtle.dig() do
            sleep(0.2)
        end
    end
end

local function digLayer()
    local currentX, currentY, currentZ = turtle.getPosition()
    local startX, startZ

    if currentY % 2 == 1 then
        startZ = excavate.size - 1 - currentZ
    else
        startZ = currentZ
    end
    if startZ % 2 == 1 then
        startX = excavate.size - 1 - currentX
    else
        startX = currentX
    end
    for iz = startZ, excavate.size - 1 do
        for ix = startX, excavate.size - 1 do
            if needToComeBack() then return true end
            dig(ix < excavate.size - 1)
            if ix == excavate.size - 1 then break end
            if not turtle.forward() then return false end
        end
        startX = 0
        if iz == excavate.size - 1 then break end
        if needToComeBack() then return true end
        if (currentY % 2 == 0 and iz % 2 == 0) then
            turtle.turnRight()
            dig(true)
            if not turtle.forward() then return false end
            turtle.turnRight()
        else
            turtle.turnLeft()
            dig(true)
            if not turtle.forward() then return false end
            turtle.turnLeft()
        end
    end
    return true
end

function deepComeBack()
    local posX, posY, posZ = turtle.getPosition()

    if not turtle.up(math.abs(posY)) then return false end
    if not turtle.comeBack() then return false end
    return true
end

if excavate == nil then
    excavate = {}
end

if (excavate == nil or excavate.size == nil) and #args < 1 then
    print("Usage: excavate <size>")
    return
end

if excavate == nil or excavate.size == nil or excavate.size < 1 then
    local size = tonumber(args[1])
    if size < 1 then
        print("Size must be greater than 0")
        return
    end
    excavate = {size = size}
    obj.saveObj(_EXCAVATE_FILE, excavate)
else
    move.loadSavedPos()
end

if excavate.position ~= nil then
    proceedReload()
end

move.historySaved = false

while true do
    if not digLayer() then
        break
    end
    if needToComeBack() then
        if not proceedReload() then
            print("Error the turtle cant move.")
            return
        end
    else
        turtle.digDown()
        if not turtle.down() then return false end
        turtle.turnRight(2)
    end
end
excavate.size = nil
if deepComeBack() then
    turtle.turnLeft(2)
    proceedDropAll()
    turtle.turnRight(2)
else
    print("Error the turtle cant move.")
end
fs.delete(move._POS_FILE)
fs.delete(_EXCAVATE_FILE)