local addonName, addon = ...
addon.Util = {}

local print = print
local Item = Item
local type = type
local string = string
local tonumber = tonumber
local strsplit = strsplit

-- Shows an error to the user.
function addon.Util.ShowError(message)
  print("|cffff0000NeverForget: " .. message .. "|r")
end

-- Helper function to return the color code associated with a |color_name|.
function addon.Util.GetColorCode(color_name)
  if color_name == "Red" then
    return "|cffff0000"
  end

  if color_name == "Green" then
    return "|cff00ff00"
  end

  if color_name == "Yellow" then
    return "|cffffff00"
  end

  if color_name == "Blue" or color_name == "IceBlue" then
    return "|cff99ccff"
  end

  -- Defaults to white
  return "|cffffffff"
end

-- Wraps the |text| with the right code to display with a color.
function addon.Util.GetColoredText(text, color_name)
  return addon.Util.GetColorCode(color_name) .. text .. "|r"
end

function addon.Util.CreateItem(item_id_or_link)
  if type(item_id_or_link) == "string" and string.find(item_id_or_link, "item:") then
    return Item:CreateFromItemLink(item_id_or_link)
  else
    return Item:CreateFromItemID(tonumber(item_id_or_link))
  end
end

function addon.Util.GetNumericalItemId(item_id_or_link)
  if type(item_id_or_link) == "number" then
    return item_id_or_link
  end
  if type(item_id_or_link) ~= "string" then
    return 0
  end
  local item_id = tonumber(string.match(item_id_or_link, "item:(%d+)"))
  if item_id then
    return item_id
  end
  return tonumber(item_id_or_link) or 0
end

function addon.Util.GetItemIdentifier(item_link)
  if type(item_link) ~= "string" then
    return item_link
  end
  local item_string = string.match(item_link, "item:([%d:-]+)")
  if not item_string then
    return item_link
  end

  local parts = { strsplit(":", item_string) }
  local item_id = tonumber(parts[1])
  if not item_id then
    return item_link
  end

  -- We ignore enchants and gems so they don't interfere with item checking
  local enchant_id = 0
  local gem1 = 0
  local gem2 = 0
  local gem3 = 0
  local gem4 = 0
  local suffix_id = tonumber(parts[7]) or 0

  if suffix_id ~= 0 then
    return string.format("item:%d:%d:%d:%d:%d:%d:%d:0:0", item_id, enchant_id, gem1, gem2, gem3, gem4, suffix_id)
  else
    return item_id
  end
end