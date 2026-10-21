os.loadAPI("move.lua")
move.loadSavedPos()

while not turtle.comeBack() do
    turtle.refuel(1)
end

local function takeSapling()
    local item = turtle.getItemDetail(1)
    if item ~= nil and item.count > 1 then
        return true
    end
    turtle.turnRight()
    turtle.select(1)
    while item == nil or item.count < 2 do
        turtle.suck(1)
        item = turtle.getItemDetail(1)
    end
    turtle.turnLeft()
end

local function arena(size, func_turn, func_rev_turn, func_action)
    for i=1,size + 1 do
        turtle.removePositionHistory()
        turtle.forward(size,
            function ()
                if i > 1 then
                    turtle.removePositionHistory()
                end
                func_action()
            end
        )
        if i == size + 2 then break end
        if i % 2 == 0 then
            func_rev_turn(1, func_action)
        else
            func_turn(1, func_action)
        end
        turtle.forward()
        if i % 2 == 0 then
            func_rev_turn(1, func_action)
        else
            func_turn(1, func_action)
        end
    end
end

local function placeSapling()
    turtle.select(1)
    if not turtle.compare() then
        turtle.place()
    end
end

local function waitTreeGrow()
    turtle.select(1)
    while turtle.compare() do
        sleep(10)
    end
end

local function cuteTree()
    turtle.select(2)
    turtle.up(6,
        function (count)
            if count > 1 and not turtle.compare() then
                return true
            end
            turtle.dig()
            turtle.digUp()
        end
    )
    turtle.down(6, function () if turtle.inspectDown() then return true end end)
end


local function prepareFuel()
    if turtle.getFuelLevel() > 100 then return 0 end
    turtle.turnLeft()
    local furnace = peripheral.wrap("front")
    turtle.select(2)
    local itemCount = turtle.getItemCount()
    if itemCount < 2 then return 0 end
    if itemCount % 2 ~= 0 then itemCount = itemCount - 1 end
    turtle.drop(itemCount / 2)
    furnace.pushItems("front", 2, itemCount / 4, 1)
    turtle.turnRight()
    return itemCount / 4
end

local function dropall()
    turtle.turnRight(2)
    for i=2, 16 do
        turtle.select(i)
        if turtle.compareTo(1) then
            turtle.transferTo(1)
        else
            turtle.drop(turtle.getItemCount())
        end
    end
    turtle.turnLeft()
    for i=2, 16 do
        turtle.drop(turtle.getItemCount())
    end
    turtle.select(1)
    if turtle.getItemCount() > 2 then
        turtle.drop(turtle.getItemCount() - 2)
    end
    turtle.turnLeft()
end

local function getFuel(fuelCount)
    turtle.turnLeft()
    local furnace = peripheral.wrap("front")
    furnace.pushItems("front", 3, fuelCount, 2)
    turtle.select(16)
    turtle.suck(fuelCount)
    turtle.refuel(fuelCount)
    turtle.turnRight()
end

local function turtleSuck()
    turtle.suck()
end

while true do
    takeSapling()
    turtle.forward(2)
    placeSapling()
    waitTreeGrow()
    cuteTree()
    turtle.turnLeft(2, turtleSuck)
    turtle.forward(1, turtleSuck)
    turtle.turnRight(1, turtleSuck)
    turtle.forward(2, turtleSuck)
    turtle.turnRight(2, turtleSuck)
    arena(4, turtle.turnLeft, turtle.turnRight, turtleSuck)
    turtle.comeBack()
    local fuelInFurnace = prepareFuel()
    dropall()
    if fuelInFurnace ~= nil and fuelInFurnace > 0 then
        sleep((fuelInFurnace * 10) + 0.5)
        getFuel(fuelInFurnace)
    end
end
