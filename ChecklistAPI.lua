local addonName, addon = ...
addon.API = {}

local ipairs = ipairs
local table = table
local tonumber = tonumber
local strsplit = strsplit
local StaticPopup_Show = StaticPopup_Show
local StaticPopupDialogs = StaticPopupDialogs
local Item = Item

local function GetChecklists()
  return NeverForget_DB.checklists
end

local function GetChecklist(checklistIndex)
  return NeverForget_DB.checklists[checklistIndex]
end

local on_change_callback = nil
local function CallOnChangeCallback()
  on_change_callback()
end

local function CreateChecklist(name)
  local new_index = #NeverForget_DB.checklists + 1

  local checklist = {}
  checklist.name = name
  checklist.item_list = {}
  checklist.include_bank = false
  checklist.visible = true

  NeverForget_DB.checklists[new_index] = checklist

  CallOnChangeCallback()
end

local function RenameChecklist(checklistIndex, new_name)
  local checklist = GetChecklist(checklistIndex)

  checklist.name = new_name

  CallOnChangeCallback()
end

local function DeleteChecklist(checklistIndex)
  local checklists = GetChecklists()

  -- Cannot delete a checklist if there is only one left.
  if #checklists == 1 then
    addon.Util.ShowError("Cannot delete the last checklist.")
    return
  end

  table.remove(checklists, checklistIndex)

  CallOnChangeCallback()
end

--------------------------------------------------------------------------------

function addon.API.IsChecklistVisible(checklistIndex)
  return NeverForget_DB.checklists[checklistIndex].visible
end

function addon.API.ToggleChecklistVisibility(checklistIndex)
  local checklist =  NeverForget_DB.checklists[checklistIndex]

  checklist.visible = not checklist.visible

  CallOnChangeCallback()
end

function addon.API.SetOnChangeCallback(callback)
  on_change_callback = callback
end

function addon.API.IsHidden()
  if NeverForget_DB.hidden == nil then
    NeverForget_DB.hidden = false
  end
  return NeverForget_DB.hidden
end

function addon.API.ToggleHidden()
  NeverForget_DB.hidden = not NeverForget_DB.hidden
end

function addon.API.IsMinimized()
  return NeverForget_DB.minimized
end

function addon.API.ToggleMinimized()
  NeverForget_DB.minimized = not NeverForget_DB.minimized
end

function addon.API.Initialize()
  if not NeverForget_DB then
    NeverForget_DB = {}
    NeverForget_DB.version = 1

    NeverForget_DB.visible = true
    NeverForget_DB.minimized = false
    NeverForget_DB.hidden = false
    NeverForget_DB.minimap_button_visible = true
    NeverForget_DB.minimap = {
      hide = false,
    }
    NeverForget_DB.tooltips_enabled = true
    NeverForget_DB.width = 260

    NeverForget_DB.checklists = {}

    -- There must always exists at least one checklist.
    -- Not using CreateChecklist() to avoid calling CallOnChangeCallback()
    local new_index = #NeverForget_DB.checklists + 1

    local checklist = {}

    checklist.name = "Checklist"
    checklist.item_list = {}
    checklist.include_bank = false
    checklist.visible = true

    NeverForget_DB.checklists[new_index] = checklist
  end

  if not NeverForget_DB.minimap then
    NeverForget_DB.minimap = {
      hide = not addon.API.IsMinimapButtonVisible(),
    }
  end

    -- Initialize delete list confirm popup
  StaticPopupDialogs["NEVERFORGET_API_CONFIRM_DELETE"] = {
    text = "Are you sure you want to delete the list\n|cff99ccff%s|r?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function(self, data)
        DeleteChecklist(data)
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
  }

    -- Initialize delete list confirm popup
  StaticPopupDialogs["NEVERFORGET_API_CONFIRM_RENAME"] = {
    text = "Please enter a new name for the list\n|cff99ccff%s|r",
    button1 = "Accept",
    button2 = "Cancel",
    OnAccept = function(self, data)
      local editBox = self.editBox or self.EditBox
      local text = editBox:GetText()
      RenameChecklist(data, text)
    end,
    EditBoxOnEnterPressed = function(self, data)
      local parent = self:GetParent()
      local text = self:GetText()
      RenameChecklist(parent.data, text)
      parent:Hide()
    end,
    timeout = 0,
    hasEditBox = true,
    whileDead = true,
    enterClicksFirstButton = true,
    hideOnEscape = true,
    preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
  }

    -- Initialize delete list confirm popup
  StaticPopupDialogs["NEVERFORGET_API_CONFIRM_NEWNAME"] = {
    text = "Please enter a name for the new list.",
    button1 = "Accept",
    button2 = "Cancel",
    OnAccept = function(self, data, data2)
      local editBox = self.editBox or self.EditBox
      local text = editBox:GetText()
      CreateChecklist(text)
    end,
    EditBoxOnEnterPressed = function(self, data)
      local parent = self:GetParent()
      local text = self:GetText()
      CreateChecklist(text)
      parent:Hide()
    end,
    timeout = 0,
    hasEditBox = true,
    whileDead = true,
    enterClicksFirstButton = true,
    hideOnEscape = true,
    preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
  }

  -- Initialize reset database confirm popup
  StaticPopupDialogs["NEVERFORGET_API_CONFIRM_RESET"] = {
    text = "Are you sure you want to reset all NeverForget checklist data?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function(self)
      addon.API.ResetDatabase()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
  }
end

function addon.API.ResetDatabase()
  NeverForget_DB = nil
  addon.API.Initialize()
  CallOnChangeCallback()
  if addon.options_panel then
    if addon.options_panel.refresh then
      addon.options_panel:refresh()
    end
    if addon.refresh_icon_callback then
      addon.refresh_icon_callback()
    elseif addon.show_icon_callback then
      addon.show_icon_callback()
    end
  end
  if addon.CloseEditMode then
    addon.CloseEditMode()
  end
  print("|cffff0000NeverForget: Database has been reset to defaults.|r")
end

function addon.API.RenameChecklist(checklistIndex)
  local dialog = StaticPopup_Show("NEVERFORGET_API_CONFIRM_RENAME", addon.API.GetChecklistName(checklistIndex))
  if dialog then
    dialog.data = checklistIndex
  end
end

function addon.API.CreateChecklist()
  StaticPopup_Show("NEVERFORGET_API_CONFIRM_NEWNAME")
end

function addon.API.DeleteChecklist(checklistIndex)
  local dialog = StaticPopup_Show("NEVERFORGET_API_CONFIRM_DELETE", addon.API.GetChecklistName(checklistIndex))
  if dialog then
    dialog.data = checklistIndex
  end
end

-- Given the |item_id|, returns the index and the value of this item in the
-- item list. Returns nil if the item is not present in the item list.
local function FindElementInItemList(item_list, item_id)
  for index, element in ipairs(item_list) do
    if element.item_id == item_id then
      return index, element
    end
  end
  return nil, nil
end

function addon.API.ToggleIncludeBank(checklistIndex)
  local checklist = GetChecklist(checklistIndex)

  checklist.include_bank = not checklist.include_bank

  CallOnChangeCallback()
end

function addon.API.IsBankIncluded(checklistIndex)
  local checklist = GetChecklist(checklistIndex)

  return checklist.include_bank
end

-- Adds an item and its count to the item list. If the item already exists in
-- the list, the count is overwritten with the new one. If the count is zero,
-- the item is removed from the list.
function addon.API.AddItemToItemList(item_list, item_id, item_count)
  if item_count == 0 then
    addon.Util.ShowError("Item count must not be zero.")
    return
  end

  local index, element = FindElementInItemList(item_list, item_id)
  if element ~= nil then
    return
  end

  element = {}
  index = #item_list + 1
  item_list[index] = element

  element.item_id = item_id
  element.item_count = item_count

  -- Sort the list.
  table.sort(item_list, function(a, b)
    local a_num = addon.Util.GetNumericalItemId(a.item_id)
    local b_num = addon.Util.GetNumericalItemId(b.item_id)
    if a_num ~= b_num then
      return a_num < b_num
    else
      return tostring(a.item_id) < tostring(b.item_id)
    end
  end)
end

-- Modifies the item count of an item in a specific list.
function addon.API.ModifyItemCount(item_list, item_id, item_count)
  if item_count == 0 then
    addon.Util.ShowError("Item count must not be zero.")
    return
  end

  local index, element = FindElementInItemList(item_list, item_id)
  if element == nil then
    return
  end

  item_list[index].item_count = item_count
end

function addon.API.GetItemList(checklistIndex)
  local checklist = GetChecklist(checklistIndex)

  return checklist.item_list
end

function addon.API.SetItemList(checklistIndex, item_list)
  local checklist = GetChecklist(checklistIndex)

  checklist.item_list = item_list

  CallOnChangeCallback()
end

function addon.API.RemoveItemFromItemList(item_list, item_index)
  table.remove(item_list, item_index)
end

-------------------------------------------------------------------------------

-- Parses |item_id_text| and returns a valid item ID. Returns nil on error.
local function ValidateItemId(item_id_text)
  -- Check if the text is empty.
  if item_id_text == "" then
    addon.Util.ShowError("Missing item ID")
    return nil
  end

  -- Check if the text can be converted to a number.
  local item_id = tonumber(item_id_text)
  if item_id == nil then
    addon.Util.ShowError("Item ID is not a number")
    return nil
  end

  -- Check if an item exists with this ID.
  local item = Item:CreateFromItemID(item_id)
  if item:IsItemEmpty() then
    addon.Util.ShowError("Invalid item ID")
    return nil
  end

  -- Validation passed.
  return item_id
end

-- Parses |item_count_text| and returns a valid item count. Returns nil on
-- error.
local function ValidateItemCount(item_count_text)
  -- Check if the text can be converted to a number.
  local item_count = tonumber(item_count_text)
  if item_count == nil then
    addon.Util.ShowError("Item count is not a number")
    return nil
  end

  -- Check if the item count returns either a positive number or is equal to
  -- zero.
  if item_count < 0 then
    addon.Util.ShowError("Item count must be zero or higher")
    return nil
  end

  -- Validation passed.
  return item_count
end


-- TODO migrate
-- Resets and initializes the list from an import string. An import string is a
-- comma-separated list of item_id and count pairs.
-- Ex. 123:10,4398:5
function addon.API.ImportChecklistString(checklistIndex, import_string)
  -- Reset the checklist.
  new_checklist = {}

  local index = 1
  while import_string ~= nil and import_string ~= "" do
    -- Avoids freezing the UI if too many items are entered.
    if index == 100 then
      addon.Util.ShowError("100 items limit exceeded.")
      return
    end

    local current_element, new_import_string = strsplit(",", import_string, 2)
    import_string = new_import_string

    local item_id_text, item_count_text = strsplit(":", current_element, 2)

    if item_id_text == nil or item_count_text == nil then
      addon.Util.ShowError("Error parsing import string")
      return
    end

    local item_id = ValidateItemId(item_id_text)
    if item_id == nil then
      return
    end

    local item_count = ValidateItemCount(item_count_text)
    if item_count == nil then
      return
    end

    index = index + 1

    addon.API.AddItemToItemList(new_checklist, item_id, item_count)
  end

  local checklist = GetChecklist(checklistIndex)
  
  checklist.item_list = new_checklist

  CallOnChangeCallback()
end

function addon.API.GetChecklistCount()
  return #GetChecklists()
end

-- Returns the import string that matches the current configuration of the
-- checklist.
function addon.API.GetImportString(checklistIndex)
  local checklist = GetChecklist(checklistIndex)

  local str = ""
  local is_first = true
  for index, element in ipairs(checklist.item_list) do
    if not is_first then
      str = str .. ","
    end
    str = str .. element.item_id .. ":" .. element.item_count
    is_first = false
  end
  return str
end

function addon.API.GetChecklistName(checklistIndex)
  local checklist = GetChecklist(checklistIndex)

  return checklist.name
end

function addon.API.SetMinimapButtonVisible()
  NeverForget_DB.minimap_button_visible = true
  if NeverForget_DB.minimap then
    NeverForget_DB.minimap.hide = false
  end
end

function addon.API.SetMinimapButtonHidden()
  NeverForget_DB.minimap_button_visible = false
  if NeverForget_DB.minimap then
    NeverForget_DB.minimap.hide = true
  end
end

function addon.API.IsMinimapButtonVisible()
  if NeverForget_DB.minimap and NeverForget_DB.minimap.hide ~= nil then
    NeverForget_DB.minimap_button_visible = not NeverForget_DB.minimap.hide
  elseif NeverForget_DB.minimap_button_visible == nil then
    NeverForget_DB.minimap_button_visible = true
  end
  return NeverForget_DB.minimap_button_visible
end

function addon.API.GetMinimapDB()
  if not NeverForget_DB.minimap then
    NeverForget_DB.minimap = {
      hide = not addon.API.IsMinimapButtonVisible(),
    }
  end
  return NeverForget_DB.minimap
end

function addon.API.MoveChecklistUp(checklistIndex)
  if checklistIndex <= 1 then return end
  local checklists = GetChecklists()
  local temp = checklists[checklistIndex]
  checklists[checklistIndex] = checklists[checklistIndex - 1]
  checklists[checklistIndex - 1] = temp

  CallOnChangeCallback()
end

function addon.API.MoveChecklistDown(checklistIndex)
  local checklists = GetChecklists()
  if checklistIndex >= #checklists then return end
  local temp = checklists[checklistIndex]
  checklists[checklistIndex] = checklists[checklistIndex + 1]
  checklists[checklistIndex + 1] = temp

  CallOnChangeCallback()
end

function addon.API.AreTooltipsEnabled()
  if NeverForget_DB.tooltips_enabled == nil then
    NeverForget_DB.tooltips_enabled = true
  end
  return NeverForget_DB.tooltips_enabled
end

function addon.API.SetTooltipsEnabled(enabled)
  NeverForget_DB.tooltips_enabled = enabled
end

function addon.API.GetChecklistWidth()
  if NeverForget_DB.width == nil then
    NeverForget_DB.width = 260
  end
  return NeverForget_DB.width
end

function addon.API.SetChecklistWidth(width)
  NeverForget_DB.width = width
  CallOnChangeCallback()
end