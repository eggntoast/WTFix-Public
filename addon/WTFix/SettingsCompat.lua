local _, ns = ...

local compat = {}
ns.SettingsCompat = compat

function compat.Register(panel, label)
    compat.panel = panel
    compat.label = label or "WTFix"
    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, compat.label)
        Settings.RegisterAddOnCategory(category)
        compat.category = category
        compat.mode = "modern"
        return
    end
    if InterfaceOptions_AddCategory then
        panel.name = compat.label
        InterfaceOptions_AddCategory(panel)
        compat.mode = "legacy"
    end
end

function compat.IsOpen()
    return compat.panel and compat.panel:IsShown() == true
end

function compat.Open()
    if compat.mode == "modern" and Settings and Settings.OpenToCategory and compat.category then
        local id = compat.category.ID or (compat.category.GetID and compat.category:GetID())
        Settings.OpenToCategory(id or compat.category)
        return
    end
    if InterfaceOptionsFrame_OpenToCategory and compat.panel then
        InterfaceOptionsFrame_OpenToCategory(compat.panel)
        InterfaceOptionsFrame_OpenToCategory(compat.panel)
        return
    end
    if compat.panel then compat.panel:Show() end
end

function compat.Close()
    if SettingsPanel and SettingsPanel:IsShown() and HideUIPanel then HideUIPanel(SettingsPanel) return end
    if InterfaceOptionsFrame and InterfaceOptionsFrame:IsShown() then InterfaceOptionsFrame:Hide() return end
    if compat.panel then compat.panel:Hide() end
end

function compat.Toggle()
    if compat.IsOpen() then compat.Close() else compat.Open() end
end
