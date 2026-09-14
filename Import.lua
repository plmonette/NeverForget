local addonName, addon = ...

local StaticPopupDialogs = StaticPopupDialogs
local StaticPopup_Show = StaticPopup_Show

  -- Initialize delete list confirm popup
StaticPopupDialogs["NEVERFORGET_IMPORT_CHECKLIST"] = {
  text = "Paste an import string for\n|cFFFFFF00%s|r",
  button1 = "Import",
  button2 = "Cancel",
  OnAccept = function(self, data)
    local editBox = self.editBox or self.EditBox
    local import_string = editBox:GetText()
    addon.API.ImportChecklistString(data, import_string)
  end,
  timeout = 0,
  hasEditBox = true,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
}

  -- Initialize delete list confirm popup
StaticPopupDialogs["NEVERFORGET_SHOW_IMPORT_STRING"] = {
  text = "Showing import string for\n|cFFFFFF00%s|r",
  button1 = "Ok",
  --button2 = "Cancel",
  timeout = 0,
  hasEditBox = true,
  whileDead = true,
  enterClicksFirstButton = true,
  hideOnEscape = true,
  preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
}

-- Shows the import string frame. TODO: The name of this frame is ambiguous
-- with the other frame that shows the current import string.
function addon.OpenImportFrame(checklistIndex)
  local checklist_name =  addon.API.GetChecklistName(checklistIndex)
  local dialog = StaticPopup_Show("NEVERFORGET_IMPORT_CHECKLIST", checklist_name)
  if dialog then
    dialog.data = checklistIndex
  end
end

  -- Shows the frame with the current import string.
local show_import_string_frame = nil
function addon.OpenShowImportStringWindow(checklistIndex)
  local checklist_name = addon.API.GetChecklistName(checklistIndex)
  local dialog = StaticPopup_Show("NEVERFORGET_SHOW_IMPORT_STRING", checklist_name)
  if dialog then
    local editBox = dialog.editBox or dialog.EditBox
    editBox:SetText(addon.API.GetImportString(checklistIndex))
  end
end
