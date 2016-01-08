; ############ GUI #############

GuiSet(ControlID, Param3="", SubCmd="") 
{
    If (!(SubCmd == "")) {
        GuiControl, %SubCmd%, %ControlID%, %Param3%
    } Else {
        GuiControl,, %ControlID%, %Param3%
    }
}

GuiGet(ControlID, DefaultValue="")
{
    curVal =
    GuiControlGet, curVal,, %ControlID%, %DefaultValue%
    return curVal
}

GuiAdd(ControlType, Contents, PositionInfo, AssocVar="", AssocHwnd="", AssocLabel="", Param4="") 
{
    Global
    Local av, ah, al
    av := StrPrefix(AssocVar, "v")
    al := StrPrefix(AssocLabel, "g")
    ah := StrPrefix(AssocHwnd, "hwnd")
    Gui, Add, %ControlType%, %PositionInfo% %av% %al% %ah% %Param4%, %Contents%
}

GuiAddButton(Contents, PositionInfo, AssocLabel="", AssocVar="", AssocHwnd="", Options="")
{
    GuiAdd("Button", Contents, PositionInfo, AssocVar, AssocHwnd, AssocLabel, Options)
}

GuiAddGroupBox(Contents, PositionInfo, AssocVar="", AssocHwnd="", AssocLabel="", Options="") 
{
    GuiAdd("GroupBox", Contents, PositionInfo, AssocVar, AssocHwnd, AssocLabel, Options)
}

GuiAddCheckbox(Contents, PositionInfo, CheckedState=0, AssocVar="", AssocHwnd="", AssocLabel="", Options="") 
{
    GuiAdd("Checkbox", Contents, PositionInfo, AssocVar, AssocHwnd, AssocLabel, "Checked" . CheckedState . " " . Options)
}

GuiAddText(Contents, PositionInfo, AssocVar="", AssocHwnd="", AssocLabel="", Options="") 
{
    GuiAdd("Text", Contents, PositionInfo, AssocVar, AssocHwnd, AssocLabel, Options)
}

GuiAddEdit(Contents, PositionInfo, AssocVar="", AssocHwnd="", AssocLabel="", Options="") 
{
    GuiAdd("Edit", Contents, PositionInfo, AssocVar, AssocHwnd, AssocLabel, Options)
}

AddToolTip(con, text, Modify=0){
    Static TThwnd, GuiHwnd
    TInfo =
    UInt := "UInt"
    Ptr := (A_PtrSize ? "Ptr" : UInt)
    PtrSize := (A_PtrSize ? A_PtrSize : 4)
    Str := "Str"
    ; defines from Windows MFC commctrl.h
    WM_USER := 0x400
    TTM_ADDTOOL := (A_IsUnicode ? WM_USER+50 : WM_USER+4)           ; used to add a tool, and assign it to a control
    TTM_UPDATETIPTEXT := (A_IsUnicode ? WM_USER+57 : WM_USER+12)    ; used to adjust the text of a tip
    TTM_SETMAXTIPWIDTH := WM_USER+24                                ; allows the use of multiline tooltips
    TTF_IDISHWND := 1
    TTF_CENTERTIP := 2
    TTF_RTLREADING := 4
    TTF_SUBCLASS := 16
    TTF_TRACK := 0x0020
    TTF_ABSOLUTE := 0x0080
    TTF_TRANSPARENT := 0x0100
    TTF_PARSELINKS := 0x1000
    If (!TThwnd) {
        Gui, +LastFound
        GuiHwnd := WinExist()
        TThwnd := DllCall("CreateWindowEx"
                    ,UInt,0
                    ,Str,"tooltips_class32"
                    ,UInt,0
                    ,UInt,2147483648
                    ,UInt,-2147483648
                    ,UInt,-2147483648
                    ,UInt,-2147483648
                    ,UInt,-2147483648
                    ,UInt,GuiHwnd
                    ,UInt,0
                    ,UInt,0
                    ,UInt,0)
    }
    ; TOOLINFO structure
    cbSize := 6*4+6*PtrSize
    uFlags := TTF_IDISHWND|TTF_SUBCLASS|TTF_PARSELINKS
    VarSetCapacity(TInfo, cbSize, 0)
    NumPut(cbSize, TInfo)
    NumPut(uFlags, TInfo, 4)
    NumPut(GuiHwnd, TInfo, 8)
    NumPut(con, TInfo, 8+PtrSize)
    NumPut(&text, TInfo, 6*4+3*PtrSize)
    NumPut(0,TInfo, 6*4+6*PtrSize)
    DetectHiddenWindows, On
    If (!Modify) {
        DllCall("SendMessage"
            ,Ptr,TThwnd
            ,UInt,TTM_ADDTOOL
            ,Ptr,0
            ,Ptr,&TInfo
            ,Ptr) 
        DllCall("SendMessage"
            ,Ptr,TThwnd
            ,UInt,TTM_SETMAXTIPWIDTH
            ,Ptr,0
            ,Ptr,A_ScreenWidth) 
    }
    DllCall("SendMessage"
        ,Ptr,TThwnd
        ,UInt,TTM_UPDATETIPTEXT
        ,Ptr,0
        ,Ptr,&TInfo
        ,Ptr)

}

GetScreenInfo()
{
    SysGet, TotalScreenWidth, 78
    SysGet, TotalscreenHeight, 79
    SysGet, MonitorCount, 80
    
    Globals.Set("MonitorCount", MonitorCount)
    Globals.Set("TotalScreenWidth", TotalScreenWidth)
    Globals.Set("TotalScreenHeight", TotalscreenHeight)    
}

; ######### UNHANDLED CASE DIALOG ############

ShowUnhandledCaseDialog()
{
    Global Msg, Globals
    Static UnhDlg_EditItemText
    
    Gui, 3:New,, Unhandled Case
    Gui, 3:Color, FFFFFF
    Gui, 3:Add, Picture, x25 y25 w36 h36, %A_ScriptDir%\data\info.png
    Gui, 3:Add, Text, x65 y31 w500 h100, % Msg.Unhandled
    Gui, 3:Add, Edit, x65 y96 w400 h120 ReadOnly vUnhDlg_EditItemText, % Globals.Get("ItemText", "Error: could'nt get item text (system clipboard modified?). Please try again or report the item manually.")
    Gui, 3:Add, Text, x-5 y230 w500 h50 -Background 
    Gui, 3:Add, Button, x195 y245 w100 h25 gUnhandledDlg_ShowItemText, Show In Notepad
    Gui, 3:Add, Button, x300 y245 w90 h25 gVisitForumsThread, Forums Thread
    Gui, 3:Add, Button, x395 y245 w86 h25 gUnhandledDlg_OK Default, OK
    Gui, 3:Show, Center w490 h280,
    Gui, Font, s10, Courier New
    Gui, Font, s9, Consolas  
    GuiControl, Font, UnhDlg_EditItemText
    return
}