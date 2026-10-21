function loadObj(file)
    local objFile = fs.open(file, 'r')
    if not objFile then return nil end
    local text = objFile.readAll()
    objFile.close()
    if not text or text == "" then return nil end
    return textutils.unserialise(text)
end

function saveObj(file, obj)
    if not obj then return false end
    local objFile = fs.open(file, 'w')
    if not objFile then return false end
    local text = textutils.serialise(obj)
    if not text or text == "" then
        objFile.close()
        return false
    end
    objFile.write(text)
    objFile.close()
    return true
end
