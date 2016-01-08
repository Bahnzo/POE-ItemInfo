; Windows system tray icon
; possible values: poe.ico, poe-bw.ico, poe-web.ico, info.ico
; set before creating the settings UI so it gets used for the settigns dialog as well
Menu, Tray, Icon, %A_ScriptDir%\data\poe-bw.ico

ReadConfig()
Sleep, 100
CreateSettingsUI()

Menu, TextFiles, Add, Valuable Uniques, EditValuableUniques
Menu, TextFiles, Add, Valuable Gems, EditValuableGems
Menu, TextFiles, Add, Dropy Only Gems, EditDropOnlyGems
Menu, TextFiles, Add, Currency Rates, EditCurrencyRates


; Menu tooltip
RelVer := Globals.Get("ReleaseVersion")
Menu, Tray, Tip, Path of Exile Item Info %RelVer%

Menu, Tray, NoStandard
Menu, Tray, Add, About..., MenuTray_About
Menu, Tray, Add, PoE Item Info Settings, ShowSettingsUI
Menu, Tray, Add ; Separator
Menu, Tray, Add, Edit, :TextFiles
Menu, Tray, Add ; Separator
Menu, Tray, Standard
Menu, Tray, Default, PoE Item Info Settings