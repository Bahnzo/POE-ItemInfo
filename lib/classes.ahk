class Fonts {
    
    Init(FontSizeFixed, FontSizeUI) 
    {
        this.FontSizeFixed := FontSizeFixed
        this.FontSizeUI := FontSizeUI
        this.FixedFont := this.CreateFixedFont(FontSizeFixed)
        this.UIFont := this.CreateUIFont(FontSizeUI)
    }
    
    CreateFixedFont(FontSize_)
    {
        Options :=
        If (!(FontSize_ == "")) 
        {
            Options = s%FontSize_%
        }
        Gui Font, %Options%, Courier New
        Gui Font, %Options%, Consolas
        Gui Add, Text, HwndHidden, 
        SendMessage, 0x31,,,, ahk_id %Hidden%
        return ErrorLevel
    }

    CreateUIFont(FontSize_)
    {
        Options :=
        If (!(FontSize_ == "")) 
        {
            Options = s%FontSize_%
        }
        Gui Font, %Options%, Tahoma
        Gui Font, %Options%, Segoe UI
        Gui Add, Text, HwndHidden, 
        SendMessage, 0x31,,,, ahk_id %Hidden%
        return ErrorLevel
    }
    
    Set(NewFont)
    {
        AhkExe := GetAhkExeFilename()
        SendMessage, 0x30, NewFont, 1,, ahk_class tooltips_class32 ahk_exe %AhkExe%
        ; Development versions of AHK
        SendMessage, 0x30, NewFont, 1,, ahk_class tooltips_class32 ahk_exe AutoHotkeyA32.exe
        SendMessage, 0x30, NewFont, 1,, ahk_class tooltips_class32 ahk_exe AutoHotkeyU32.exe
        SendMessage, 0x30, NewFont, 1,, ahk_class tooltips_class32 ahk_exe AutoHotkeyU64.exe
    }
    
    SetFixedFont(FontSize_=-1)
    {
        If (FontSize_ == -1)
        {
            FontSize_ := this.FontSizeFixed
        }
        Else
        {
            this.FontSizeFixed := FontSize_
            this.FixedFont := this.CreateFixedFont(FontSize_)
        }
        this.Set(this.FixedFont)
    }

    SetUIFont(FontSize_=-1)
    {
        If (FontSize_ == -1)
        {
            FontSize_ := this.FontSizeUI
        }
        Else
        {
            this.FontSizeUI := FontSize_
            this.UIFont := this.CreateUIFont(FontSize_)
        }
        this.Set(this.UIFont)
    }
    
    GetFixedFont()
    {
        return this.FixedFont
    }
    
    GetUIFont()
    {
        return this.UIFont
    }
}

class ItemData_ {

    Links := ""
    Stats := ""
    NamePlate := ""
    Affixes := ""
    FullText := ""
    IndexAffixes := -1
    IndexLast := -1
    PartsLast := ""
    Rarity := ""
    Parts := []
    
    ClearParts() 
    {
        Loop, % this.Parts.MaxIndex()
        {
            this.Parts.Remove(this.Parts.MaxIndex())
        }
    }
}
ItemData := new ItemData_()

class Item {
    Name := ""
    TypeName := ""
    Quality := ""
    BaseLevel := ""
    RarityLevel := ""
    BaseType := ""
    SubType := ""
    GripType := ""
    Level := ""
  MapLevel := ""
    MaxSockets := ""
    IsUnidentified := ""
    IsCorrupted := ""
    IsGem := ""
    IsCurrency := ""
    IsUnique := ""
    IsRare := ""
    IsBow := ""
    IsFlask := ""
    IsBelt := ""
    IsRing := ""
    IsUnsetRing := ""
    IsAmulet := ""
    IsTalisman := ""
    IsSingleSocket := ""
    IsFourSocket := ""
    IsThreeSocket := ""
    IsQuiver := ""
    IsWeapon := ""
    IsMap := ""
    IsMirrored := ""
    HasEffect := ""
}
Item := new Item()

class AffixTotals_ {

    NumPrefixes := 0
    NumSuffixes := 0
    NumTotals := 0
    
    Reset() 
    {
        this.NumPrefixes := 0
        this.NumSuffixes := 0
        this.NumTotals := 0
    }
}
AffixTotals := new AffixTotals_()

class AffixLines_ {
    
    __New()
    {
        this.Length := 0
    }
    
    ; Sets fields to empty string
    Clear(Index)
    {
        this[Index] := ""
    }
    
    ClearAll()
    {
        Loop, % this.MaxIndex()
        {
            this.Clear(A_Index)
        }
    }
    
    ; Actually removes fields
    Reset() 
    {
        Loop, % this.MaxIndex()
        {
            this.Remove(this.MaxIndex())
        }
        this.Length := 0
    }
    
    Set(Index, Contents)
    {
        this[Index] := Contents
        this.Length := this.MaxIndex()
    }
}
AffixLines := new AffixLines_()

#Include %A_ScriptDir%\lib\classes\UserOptions.ahk