local core = {}

core.deep_print = function(self, obj, indent, seen)
  indent = indent or ""
  seen = seen or {}

  if seen[obj] then
    print(indent .. "* (already seen)")
    return
  end
  seen[obj] = true

  if type(obj) ~= "table" then
    print(indent .. tostring(obj))
    return
  end

  for k, v in pairs(obj) do
    local key = tostring(k)
    if type(v) == "table" then
      print(indent .. "[" .. key .. "] => (table)")
      self:deep_print(v, indent .. "  ", seen)
    elseif type(v) == "function" then
      print(indent .. "[" .. key .. "] => <function>")
    else
      print(indent .. "[" .. key .. "] => " .. tostring(v))
    end
  end
end

core.dump_fields_recursive = function(self, obj)
    local tdef = obj:get_type_definition()
    print("Fields:")
    while tdef do
        for _, field in ipairs(tdef:get_fields()) do
            local ok, val = pcall(function()
                return field:get_data(obj)
            end)
            print(" ", field:get_name(), ok and val or "ERR")
        end
        tdef = tdef:get_parent_type()
    end
end

core.dump_methods_recursive = function(self, obj)
    local tdef = obj:get_type_definition()
    print("Methods:")
    while tdef do
        for _, method in ipairs(tdef:get_methods()) do
            print(" ", method:get_name(), "-", tostring(method))
        end
        tdef = tdef:get_parent_type()
    end
end

core.dump_object = function(self, obj)
    self:dump_methods_recursive(obj)
end

return core