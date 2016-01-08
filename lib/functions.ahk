GetAhkExeFilename(Default_="AutoHotkey.exe")
{
    AhkExeFilename := Default_
    If (A_AhkPath)
    {
        StringSplit, AhkPathParts, A_AhkPath, \
        Loop, % AhkPathParts0
        {
            IfInString, AhkPathParts%A_Index%, .exe
            {
                AhkExeFilename := AhkPathParts%A_Index%
                Break
            }
        }
    }
    return AhkExeFilename
}

OpenCreateDataTextFile(Filename)
{
    Filepath := A_ScriptDir . "\data\" . Filename
    IfExist, % Filepath
    {
        Run, % Filepath
    }
    Else
    {
        
        File := FileOpen(Filepath, "w")
        if !IsObject(File)
        {
            MsgBox, 16, Can't create %A_ScriptDir%\data\ValuableUniques.txt
            return
        }
        File.Close()
        Run, % Filepath
    }
    return

    Run, %A_ScriptDir%\data\%Filename%
    return
}

ParseElementalDamage(String, DmgType, ByRef DmgLo, ByRef DmgHi)
{
    IfInString, String, %DmgType% Damage 
    {
        IfInString, String, Converted to or IfInString, String, taken as
        {
            return
        }
        IfNotInString, String, increased 
        {
            StringSplit, Arr, String, %A_Space%
            StringSplit, Arr, Arr2, -
            DmgLo := Arr1
            DmgHi := Arr2
        }
    }
}

; Function that checks item type name against entries 
; from ItemList.txt to get the item's base level
; Added by kongyuyu, changed by hazydoc
CheckBaseLevel(ItemTypeName)
{
    ; Added to correctly id Superior items
    ; code by sirmanky
    If(InStr(ItemTypeName, "Superior") == 1)
        ItemTypeName := SubStr(ItemTypeName, 10)
    ItemListArray = 0
    Loop, Read, %A_ScriptDir%\data\ItemList.txt 
    {  
        ; This loop retrieves each line from the file, one at a time.
        ItemListArray += 1  ; Keep track of how many items are in the array.
        StringSplit, NameLevel, A_LoopReadLine, |,
        Array%ItemListArray%1 := NameLevel1  ; Store this line in the next array element.
        Array%ItemListArray%2 := NameLevel2
    }

    Loop %ItemListArray% {
        element := Array%A_Index%1
    
        ;original line restored by Bahnzo to restore Base Item Level
        ;IfInString, ItemTypeName, %element%
        If(ItemTypeName == element) 
        {
            BaseLevel := Array%A_Index%2
            Break
        }
    }
    return BaseLevel
}

CheckRarityLevel(RarityString)
{
    IfInString, RarityString, Normal
        return 1
    IfInString, RarityString, Magic
        return 2
    IfInString, RarityString, Rare
        return 3
    IfInString, RarityString, Unique
        return 4
    return 0 ; unknown rarity. shouldn't happen!
}

#Include %A_ScriptDir%\lib\functions\ParseItemType.ahk

GetClipboardContents(DropNewlines=False)
{
    Result =
    If Not DropNewlines
    {
        Loop, Parse, Clipboard, `n, `r
        {
            Result := Result . A_LoopField . "`r`n"
        }
    }
    Else
    {   
        Loop, Parse, Clipboard, `n, `r
        {
            Result := Result . A_LoopField
        }
    }
    return Result
}

SetClipboardContents(String)
{
    Clipboard := String
}

; Splits StrInput on StrDelimiter. Returns an object that has a 'length' field 
; containing the number of parts and 0 .. (length) fields containing the substrings.
; Example: if parts is the object returned by this function, then
;   'parts.length' gives the number of parts
;   'parts[1]' gives the first part (if there is one)
; Note: if StrDelimiter is not present in StrInput, length == 1 and parts[1] == StrInput
; Note2: as per AHK docs, parts.(Min|Max)Index() also work of course.
SplitString(StrInput, StrDelimiter)
{
    TempDelim := "``"
    Chunks := Object()
    StringReplace, TempResult, StrInput, %StrDelimiter%, %TempDelim%, All
    StringSplit, Parts, TempResult, %TempDelim%
    Chunks["length"] := Parts0
    Loop, %Parts0%
    {
        Chunks[A_Index] := Parts%A_Index%
    }
    return Chunks
}

; TODO: LookupAffixBracket and LookupAffixData contain a lot of duplicate code.

; Look up just the most applicable bracket for an affix.
; Most applicable means Value is between bounds of bracket range or 
; highest entry possible given the item level.
;
; Returns "#-#" format range
;
; If Value is unspecified ("") return the max possible 
; bracket based on item level
LookupAffixBracket(Filename, ItemLevel, Value="", ByRef BracketLevel="", ByRef BracketIndex=0)
{
    AffixLevel := 0
    AffixDataIndex := 0
    If (Not Value == "")
    {
        ValueLo := Value             ; Value from ingame tooltip
        ValueHi := Value             ; For single values (which most of them are) ValueLo == ValueHi
        ParseRange(Value, ValueHi, ValueLo)
    }
    LookupIsDoubleRange := False ; For affixes like "Adds +# ... Damage" which have a lower and an upper bound range
    BracketRange := "n/a"
    Loop, Read, %A_ScriptDir%\%Filename%
    {  
        AffixDataIndex += 1
        StringSplit, AffixDataParts, A_LoopReadLine, |,
        RangeLevel := AffixDataParts1
        RangeValues := AffixDataParts2
        If (RangeLevel > ItemLevel)
        {
            AffixDataIndex -= 1 ; Since we added 1 above, before we noticed range level is above item level 
            Break
        }
        IfInString, RangeValues, `,
        {
            LookupIsDoubleRange := True
        }
        If (LookupIsDoubleRange)
        {
            ; Example lines from txt file database for double range lookups:
            ;  3|1,14-15
            ; 13|1-3,35-37
            StringSplit, DoubleRangeParts, RangeValues, `,
            LB := DoubleRangeParts%DoubleRangeParts%1
            UB := DoubleRangeParts%DoubleRangeParts%2
            ; Default case: lower bound is single value: #
            ; see level 3 case in example lines above
            LBMin := LB
            LBMax := LB
            UBMin := UB
            UBMax := UB
            IfInString, LB, -
            {
                ; Lower bound is a range: #-#q
                ParseRange(LB, LBMax, LBMin)
            }
            IfInString, UB, -
            {
                ParseRange(UB, UBMax, UBMin)
            }
            LBPart = %LBMin%
            UBPart = %UBMax%
            ; Record bracket range if it is within bounds of the text file entry
            If (Value == "" or (((ValueLo >= LBMin) and (ValueLo <= LBMax)) and ((ValueHi >= UBMin) and (ValueHi <= UBMax))))
            {
                BracketRange = %LBPart%-%UBPart%
                AffixLevel = %RangeLevel%
            }
        }
        Else
        {
            ParseRange(RangeValues, HiVal, LoVal)
            ; Record bracket range if it is within bounds of the text file entry
            If (Value == "" or ((ValueLo >= LoVal) and (ValueHi <= HiVal)))
            {
                BracketRange = %LoVal%-%HiVal%
                AffixLevel = %RangeLevel%
            }
        }
        If (Value == "") 
        {
            AffixLevel = %RangeLevel%
        }
    }
    BracketIndex := AffixDataIndex
    BracketLevel := AffixLevel
    return BracketRange
}

; Look up complete data for an affix. Depending on settings flags 
; this may include many things, and will return a string used for
; end user display rather than further calculations. 
; Use LookupAffixBracket if you need a range format to do calculations with.
LookupAffixData(Filename, ItemLevel, Value, ByRef BracketLevel="", ByRef Tier=0)
{
    Global Opts
    
    AffixLevel := 0
    AffixDataIndex := 0
    ValueLo := Value             ; Value from ingame tooltip
    ValueHi := Value             ; For single values (which most of them are) ValueLo == ValueHi
    ValueIsMinMax := False       ; Treat Value as min/max units (#-#) or as single unit (#)
    LookupIsDoubleRange := False ; For affixes like "Adds +# ... Damage" which have a lower and an upper bound range
    FirstRangeValues =
    BracketRange := "n/a"
    MaxRange =
    FinalRange = 
    MaxLevel := 1
    RangeLevel := 1
    Tier := 0
    MaxTier := 0
    IfInString, Value, -
    {
        ParseRange(Value, ValueHi, ValueLo)
        ValueIsMinMax := True
    }
    ; TODO refactor pre-pass into its own method
    ; Pre-pass to determine max tier
    Loop, Read, %A_ScriptDir%\%Filename%
    {  
        StringSplit, AffixDataParts, A_LoopReadLine, |,
        RangeLevel := AffixDataParts1
        If (Globals.Get("TierRelativeToItemLevelOverride", Opts.TierRelativeToItemLevel) and (RangeLevel > ItemLevel))
        {
            Break
        }
        ; Yes, this is correct incrementing MaxTier here and not before the break!
        MaxTier += 1
    }

    Loop, Read, %A_ScriptDir%\%Filename%
    {  
        AffixDataIndex += 1
        StringSplit, AffixDataParts, A_LoopReadLine, |,
        RangeValues := AffixDataParts2
        RangeLevel := AffixDataParts1
        If (AffixDataIndex == 1)
        {
            FirstRangeValues := RangeValues
        }
        If (Globals.Get("TierRelativeToItemLevelOverride", Opts.TierRelativeToItemLevel) and (RangeLevel > ItemLevel))
        {
            Break
        }
        MaxLevel := RangeLevel
        IfInString, RangeValues, `,
        {
            LookupIsDoubleRange := True
        }
        If (LookupIsDoubleRange)
        {
            ; Variables for min/max double ranges, like in the "Adds +# ... Damage" case
            ;       Global LBMin     ; (L)ower (B)ound minium value
            ;       Global LBMax     ; (L)ower (B)ound maximum value
            ;       GLobal UBMin     ; (U)pper (B)ound minimum value
            ;       GLobal UBMax     ; (U)pper (B)ound maximum value
            ;       ; same, just for the first range's values
            ;       Global FRLBMin   
            ;       Global FRLBMax   
            ;       Global FRUBMin   
            ;       Global FRUBMax   
            ; Example lines from txt file database for double range lookups:
            ;  3|1,14-15
            ; 13|1-3,35-37
            StringSplit, DoubleRangeParts, RangeValues, `,
            LB := DoubleRangeParts%DoubleRangeParts%1
            UB := DoubleRangeParts%DoubleRangeParts%2
            ; Default case: lower bound is single value: #
            ; see level 3 case in example lines above
            LBMin := LB
            LBMax := LB
            UBMin := UB
            UBMax := UB
            IfInString, LB, -
            {
                ; Lower bound is a range: #-#
                ParseRange(LB, LBMax, LBMin)
            }
            IfInString, UB, -
            {
                ParseRange(UB, UBMax, UBMin)
            }
            If (AffixDataIndex == 1)
            {
                StringSplit, FirstDoubleRangeParts, FirstRangeValues, `,
                FRLB := FirstDoubleRangeParts%FirstDoubleRangeParts%1
                FRUB := FirstDoubleRangeParts%FirstDoubleRangeParts%2
                ParseRange(FRUB, FRUBMax, FRUBMin)
                ParseRange(FRLB, FRLBMax, FRLBMin)
            }
            If ((LBMin == LBMax) or Opts.CompactDoubleRanges) 
            {
                LBPart = %LBMin%
            }
            Else
            {
                LBPart = %LBMin%-%LBMax%
            }
            If ((UBMin == UBMax) or Opts.CompactDoubleRanges) 
            {
                UBPart = %UBMax%
            }
            Else
            {
                UBPart = %UBMin%-%UBMax%
            }
            If ((FRLBMin == FRLBMax) or Opts.CompactDoubleRanges)
            {
                FRLBPart = %FRLBMin%
            }
            Else
            {
                FRLBPart = %FRLBMin%-%FRLBMax%
            }
            If (Opts.CompactDoubleRanges)
            {
                MiddlePart := "-"
            }
            Else
            {
                MiddlePart := " to "
            }
            ; Record bracket range if it is withing bounds of the text file entry
            If (((ValueLo >= LBMin) and (ValueLo <= LBMax)) and ((ValueHi >= UBMin) and (ValueHi <= UBMax)))
            {
                BracketRange = %LBPart%%MiddlePart%%UBPart%
                AffixLevel = %MaxLevel%
                Tier := ((MaxTier - AffixDataIndex) + 1)
                If (Opts.ShowAffixBracketTierTotal)
                {
                    Tier := Tier . "/" . MaxTier
                }
            }
            ; Record max possible range regardless of within bounds
            If (Opts.MaxSpanStartingFromFirst)
            {
                MaxRange = %FRLBPart%%MiddlePart%%UBPart%
            }
            Else
            {
                MaxRange = %LBPart%%MiddlePart%%UBPart%
            }
        }
        Else
        {
            If (AffixDataIndex = 1)
            {
                ParseRange(FirstRangeValues, FRHiVal, FRLoVal)
            }
            ParseRange(RangeValues, HiVal, LoVal)
            ; Record bracket range if it is within bounds of the text file entry
            If ((ValueLo >= LoVal) and (ValueHi <= HiVal))
            {
                If (LoVal = HiVal)
                {
                    BracketRange = %LoVal%
                }
                Else
                {
                    BracketRange = %LoVal%-%HiVal%
                }
                AffixLevel = %MaxLevel%
                Tier := ((MaxTier - AffixDataIndex) + 1)
                
                If (Opts.ShowAffixBracketTierTotal)
                {
                    Tier := Tier . "/" . MaxTier
                }
            }
            ; Record max possible range regardless of within bounds
            If (Opts.MaxSpanStartingFromFirst)
            {
                MaxRange = %FRLoVal%-%HiVal%
            }
            Else
            {
                MaxRange = %LoVal%-%HiVal%
            }
        }
    }
    BracketLevel := AffixLevel
    FinalRange := AssembleValueRangeFields(BracketRange, BracketLevel, MaxRange, MaxLevel)
    return FinalRange
}

AssembleValueRangeFields(BracketRange, BracketLevel, MaxRange="", MaxLevel=0)
{
    Global Opts
    
    If (Opts.ShowAffixBracket)
    {
        FinalRange := BracketRange
        If (Opts.ValueRangeFieldWidth > 0)
        {
            FinalRange := StrPad(FinalRange, Opts.ValueRangeFieldWidth, "left")
        }
        If (Opts.ShowAffixLevel)
        {
            FinalRange := FinalRange . " " . StrPad("(" . BracketLevel . ")", 4, Side="left")
        }
        Else
        {
            FinalRange := FinalRange . Opts.AffixDetailDelimiter
        }
    }
    If (MaxRange and Opts.ShowAffixMaxPossible)
    {
        If (Opts.ValueRangeFieldWidth > 0)
        {
            MaxRange := StrPad(MaxRange, Opts.ValueRangeFieldWidth, "left")
        }
        FinalRange := FinalRange . MaxRange
        If (Opts.ShowAffixLevel)
        {
            FinalRange := FinalRange . " " . StrPad("(" . MaxLevel . ")", 4, Side="left")
        }
    }
    return FinalRange
}

ParseRarity(ItemData_NamePlate)
{
    Loop, Parse, ItemData_NamePlate, `n, `r
    {
        IfInString, A_LoopField, Rarity:
        {
            StringSplit, RarityParts, A_LoopField, %A_Space%
            Break
        }
    }
    return RarityParts%RarityParts%2
}

Assert(expr, msg) 
{
    If (Not (expr))
    {
        MsgBox, 4112, Assertion Failure, %msg%
        ExitApp
    }
}

GetItemDataChunk(ItemDataText, MatchWord)
{
    Assert(StrLen(MatchWord) > 0, "GetItemDataChunk: parameter 'MatchWord' can't be empty")
    
    StringReplace, TempResult, ItemDataText, --------`r`n, ``, All  
    StringSplit, ItemDataChunks, TempResult, ``
    Loop, %ItemDataChunks0%
    {
        IfInString, ItemDataChunks%A_Index%, %MatchWord%
        {
            return ItemDataChunks%A_Index%
        }
    }
}

ParseQuality(ItemDataNamePlate)
{
    ItemQuality := 0
    Loop, Parse, ItemDataNamePlate, `n, `r
    {
        If (StrLen(A_LoopField) = 0)
        {
            Break
        }
        IfInString, A_LoopField, Unidentified
        {
            Break
        }
        IfInString, A_LoopField, Quality:
        {
            ItemQuality := RegExReplace(A_LoopField, "Quality: \+(\d+)% .*", "$1")
            Break
        }
    }
    return ItemQuality
}

ParseAugmentations(ItemDataChunk, ByRef AffixCSVList)
{
    CurAugment := ItemDataChunk
    Loop, Parse, ItemDataChunk, `n, `r
    {
        CurAugment := A_LoopField
        Globals.Set("CurAugment", A_LoopField)
        IfInString, A_LoopField, Requirements:
        {
            ; too far - Requirements: is already the next chunk
            Break
        }
        IfInString, A_LoopField, (augmented)
        {
            StringSplit, LineParts, A_LoopField, :
            AffixCSVList := AffixCSVList . "'"  . LineParts%LineParts%1 . "'"
            AffixCSVList := AffixCSVList . ", "
        }
    }
    AffixCSVList := SubStr(AffixCSVList, 1, -2)
}

ParseRequirements(ItemDataChunk, ByRef Level, ByRef Attributes, ByRef Values="")
{
    IfNotInString, ItemDataChunk, Requirements
    {
        return
    }
    Attr =
    AttrValues =
    Delim := ","
    DelimLen := StrLen(Delim)
    Loop, Parse, ItemDataChunk, `n, `r
    {    
        If StrLen(A_LoopField) = 0
        {
            Break ; Not interested in blank lines
        }
        IfInString, A_LoopField, Str
        {
            Attr := Attr . "Str" . Delim
            AttrValues := AttrValues . GetColonValue(A_LoopField) . Delim
        }
        IfInString, A_LoopField, Dex
        {
            Attr := Attr . "Dex" . Delim
            AttrValues := AttrValues . GetColonValue(A_LoopField) . Delim
        }
        IfInString, A_LoopField, Int
        {
            Attr := Attr . "Int" . Delim
            AttrValues := AttrValues . GetColonValue(A_LoopField) . Delim
        }
        IfInString, A_LoopField, Level
        {
            Level := GetColonValue(A_LoopField)
        }
    }
    ; Chop off last Delim
    If (SubStr(Attr, -(DelimLen-1)) == Delim)
    {
        Attr := SubStr(Attr, 1, -(DelimLen))
    }
    If (SubStr(AttrValues, -(DelimLen-1)) == Delim)
    {
        AttrValues := SubStr(AttrValues, 1, -(DelimLen))
    }
    Attributes := Attr
    Values := AttrValues
}

; Parses #low-#high and sets Hi to #high and Lo to #low
; if RangeChunk is just a single value (#) it will set both
; Hi and Lo to this single value (effectively making the range 1-1 if # was 1)
ParseRange(RangeChunk, ByRef Hi, ByRef Lo)
{
    IfInString, RangeChunk, -
    {
        StringSplit, RangeParts, RangeChunk, -
        Lo := RegExReplace(RangeParts1, "(\d+?)", "$1")
        Hi := RegExReplace(RangeParts2, "(\d+?)", "$1")
    }
    Else
    {
        Hi := RangeChunk
        Lo := RangeChunk
    }
}

ParseItemLevel(ItemDataText)
{
    ; XXX
    ; Add support for The Awakening Closed Beta
    ; Once TA is released we won't need to support both occurences of
    ; the word "Item level" any more...
    ItemDataChunk := GetItemDataChunk(ItemDataText, "Itemlevel:")
    If (StrLen(ItemDataChunk) <= 0)
    {
        ItemDataChunk := GetItemDataChunk(ItemDataText, "Item Level:")
    }
    
    Assert(StrLen(ItemDataChunk) > 0, "ParseItemLevel: couldn't parse item data chunk")
    
    Loop, Parse, ItemDataChunk, `n, `r
    {
        IfInString, A_LoopField, Itemlevel:
        {
            StringSplit, ItemLevelParts, A_LoopField, %A_Space%
            Result := StrTrimWhitespace(ItemLevelParts2)
            return Result
        }
        IfInString, A_LoopField, Item Level:
        {
            StringSplit, ItemLevelParts, A_LoopField, %A_Space%
            Result := StrTrimWhitespace(ItemLevelParts3)
            return Result
        }
    }
}

;;hixxie fixed. Shows MapLevel for any map base.
ParseMapLevel(ItemDataText)
{
    ItemDataChunk := GetItemDataChunk(ItemDataText, "MapTier:")
    If (StrLen(ItemDataChunk) <= 0)
    {
        ItemDataChunk := GetItemDataChunk(ItemDataText, "Map Tier:")
    }
    
    Assert(StrLen(ItemDataChunk) > 0, "ParseMapLevel: couldn't parse item data chunk")
    
    Loop, Parse, ItemDataChunk, `n, `r
    {
        IfInString, A_LoopField, MapTier:
        {
            StringSplit, MapLevelParts, A_LoopField, %A_Space%
            Result := StrTrimWhitespace(MapLevelParts2)
            return Result
        }
        IfInString, A_LoopField, Map Tier:
        {
            StringSplit, MapLevelParts, A_LoopField, %A_Space%
            Result := StrTrimWhitespace(MapLevelParts3) + 67
            return Result
        }
    }
}



ParseGemLevel(ItemDataText, PartialString="Level:")
{
    ItemDataChunk := GetItemDataChunk(ItemDataText, PartialString)
    Loop, Parse, ItemDataChunk, `n, `r
    {
        IfInString, A_LoopField, %PartialString%
        {
            StringSplit, ItemLevelParts, A_LoopField, %A_Space%
            Result := StrTrimWhitespace(ItemLevelParts2)
            return Result
        }
    }
}

StrMult(Char, Times)
{
    Result =
    Loop, %Times%
    {
        Result := Result . Char
    }
    return Result
}

StrTrimSpaceLeft(String)
{
    return RegExReplace(String, " *(.+?)", "$1")
}

StrTrimSpaceRight(String)
{
    return RegExReplace(String, "(.+?) *$", "$1")
}

StrTrimSpace(String)
{
    return RegExReplace(String, " *(.+?) *", "$1")
}

StrTrimWhitespace(String)
{
    return RegExReplace(String, "[ \r\n\t]*(.+?)[ \r\n\t]*", "$1")
}

; Pads a string with a multiple of PadChar to become a wanted total length.
; Note that Side is the side that is padded not the anchored side.
; Meaning, if you pad right side, the text will move left. If Side was an 
; anchor instead, the text would move right if anchored right.
StrPad(String, Length, Side="right", PadChar=" ")
{
    StringLen, Len, String
    AddLen := Length-Len
    If (AddLen <= 0)
    {
        return String
    }
    Pad := StrMult(PadChar, AddLen)
    If (Side == "right")
    {
        Result := String . Pad
    }
    Else
    {
        Result := Pad . String
    }
    return Result
}

; Prefix a string s with another string prefix. 
; Does nothing if s is already prefixed.
StrPrefix(s, prefix) {
    If (s == "") {
        return ""
    } Else {
        If (SubStr(s, 1, StrLen(prefix)) == prefix) {
            return s ; Nothing to do
        } Else {
            return prefix . s
        }
    }
}

BoolToString(flag) {
    If (flag == True) {
        return "True"
    } Else {
        return "False"
    }
    return "False"
}

; Formats a number with SetFormat (leaving A_FormatFloat unchanged)
; Returns formatted Num as string.
NumFormat(Num, Format)
{
    oldFormat := A_FormatFloat
    newNum := Num
    SetFormat, FloatFast, %Format%
    newNum += 0.0 ; convert to float, which applies SetFormat
    newNum := newNum . "" ; convert to string so the next SetFormat doesn't apply
    SetFormat, FloatFast, %oldFormat%
    return newNum
}

; Pads a number with prefixed 0s and optionally rounds or appends to specified decimal places width.
NumPad(Num, TotalWidth, DecimalPlaces=0) 
{
    myFormat = 0%TotalWidth%.%DecimalPlaces%
    newNum := NumFormat(Num, myFormat)
    return newNum
}

; Estimate indicator, marks end user display values as guesstimated so they can take a look at it.
MarkAsGuesstimate(ValueRange, Side="left", Indicator=" * ")
{
    Global Globals, Opts
    Globals.Set("MarkedAsGuess", True)
    return StrPad(ValueRange . Indicator, Opts.ValueRangeFieldWidth + StrLen(Indicator), Side)
}

MakeAffixDetailLine(AffixLine, AffixType, ValueRange, Tier)
{
    Global ItemData
    Delim := "|" ; Internal delimiter, used as string split char later - do not change to the user adjustable delimiter
    Line := AffixLine . Delim . ValueRange . Delim . AffixType
    If (ItemData.Rarity == "Rare" or ItemData.Rarity == "Magic")
    {
        Line := Line . Delim . Tier
    }
    return Line
}

AppendAffixInfo(Line, AffixPos)
{
    Global AffixLines
    AffixLines.Set(AffixPos, Line)
}

AssembleAffixDetails()
{
    Global Opts, AffixLines
    
    AffixLine =
    AffixType =
    ValueRange =
    AffixTier =
    NumAffixLines := AffixLines.MaxIndex()
    AffixLineParts := 0
    Loop, %NumAffixLines%
    {
        CurLine := AffixLines[A_Index]
        ProcessedLine =
        Loop, %AffixLineParts0%
        {
            AffixLineParts%A_Index% =
        }
        StringSplit, AffixLineParts, CurLine, |
        AffixLine := AffixLineParts1
        ValueRange := AffixLineParts2
        AffixType := AffixLineParts3
        AffixTier := AffixLineParts4

        Delim := Opts.AffixDetailDelimiter
        Ellipsis := Opts.AffixDetailEllipsis

        If (Opts.ValueRangeFieldWidth > 0)
        {
            ValueRange := StrPad(ValueRange, Opts.ValueRangeFieldWidth, "left")
        }
        If (Opts.MirrorAffixLines == 1)
        {
            If (Opts.MirrorLineFieldWidth > 0)
            {
                If(StrLen(AffixLine) > Opts.MirrorLineFieldWidth)
                {   
                    AffixLine := StrTrimSpaceRight(SubStr(AffixLine, 1, Opts.MirrorLineFieldWidth)) . Ellipsis
                }
                AffixLine := StrPad(AffixLine, Opts.MirrorLineFieldWidth + StrLen(Ellipsis))
            }
            ProcessedLine := AffixLine . Delim
        }
        IfInString, ValueRange, *
        {
            ValueRangeString := StrPad(ValueRange, (Opts.ValueRangeFieldWidth * 2) + (StrLen(Opts.AffixDetailDelimiter)))
        }
        Else
        {
            ValueRangeString := ValueRange
        }
        ProcessedLine := ProcessedLine . ValueRangeString . Delim
        If (Opts.ShowAffixBracketTier == 1 and Not (ItemDataRarity == "Unique") and Not StrLen(AffixTier) = 0)
        {
            If (InStr(ValueRange, "*") and Opts.ShowAffixBracketTier)
            {
                TierString := "   "
                AdditionalPadding := ""
                If (Opts.ShowAffixLevel or Opts.ShowAffixBracketTotalTier)
                {
                    TierString := ""
                }
                If (Opts.ShowAffixLevel) 
                {
                    AdditionalPadding := AdditionalPadding . StrMult(" ", Opts.ValueRangeFieldWidth)
                }
                If (Opts.ShowAffixBracketTierTotal)
                {
                    AdditionalPadding := AdditionalPadding . StrMult(" ", Opts.ValueRangeFieldWidth)

                }
                TierString := TierString . AdditionalPadding
            }
            Else 
            {
                AddedWidth := 0
                If (Opts.ShowAffixBracketTierTotal)
                {
                    AddedWidth += 2

                }
                TierString := StrPad("T" . AffixTier, 3+AddedWidth, "left")
            }
            ProcessedLine := ProcessedLine . TierString . Delim
        }
        ProcessedLine := ProcessedLine . AffixType . Delim
        Result := Result . "`n" . ProcessedLine
    }
    return Result
}

AssembleDarkShrineInfo()
{
    Global Item, ItemData
    
    AffixString := ItemData.Affixes
    Found := 0
    
    affixloop:
    Loop, Parse, AffixString, `n, `r
    {
        AffixLine := A_LoopField
        
        If (AffixLine == "" or AffixLine == "Unidentified" ) {
            ; ignore empty affixes and unidentified items
            continue affixloop
        }
        
        Found := Found + 1
        
        DsAffix := ""
        If (RegExMatch(AffixLine,"[0-9.]+% "))
        {
            DsAffix := RegExReplace(AffixLine,"[0-9.]+% ","#% ")
        } Else If (RegExMatch(AffixLine,"^\+[0-9.]+ ")) {
            DsAffix := RegExReplace(AffixLine,"^\+[0-9.]+ ","+# ")
        } Else If (RegExMatch(AffixLine,"^\-[0-9.]+ ")) {
            ; Needed for Elreon's mod on jewelry
            DsAffix := RegExReplace(AffixLine,"^\-[0-9.]+ ","-# ")
        } Else If (RegExMatch(AffixLine,"^[0-9.]+ ")) {
            DsAffix := RegExReplace(AffixLine,"^[0-9.]+ ","# ")
        } Else If (RegExMatch(AffixLine," [0-9]+-[0-9]+ ")) {
            DsAffix := RegExReplace(AffixLine," [0-9]+-[0-9]+ "," #-# ")
        } Else If (RegExMatch(AffixLine,"gain [0-9]+ (Power|Frenzy|Endurance) Charge")) {
            ; Fixes recognition of affixes like "Monsters gain # Endurance Charges every 20 seconds"
            DsAffix := RegExReplace(AffixLine,"gain [0-9]+ ","gain # ")
        } Else If (RegExMatch(AffixLine,"fire [0-9]+ additional Projectiles")) {
            ; Fixes recognition of "Monsters fire # additional Projectiles" affix
            DsAffix := RegExReplace(AffixLine,"[0-9]+","#")
        } Else If (RegExMatch(AffixLine,"^Reflects [0-9]+")) {
            ; Fixes recognition of "Reflects # Physical Damage to Melee Attackers" affix
            DsAffix := RegExReplace(AffixLine,"[0-9]+","#")
        }Else {
            DsAffix := AffixLine
        }
        
        Result := Result . "`n " . DsAffix . ":"
        
        ; DarkShrineEffects.txt
        ; File with known effects based on POE wiki and http://poe.rivsoft.net/shrines/shrines.js  by https://www.reddit.com/user/d07RiV
        Loop, Read, %A_ScriptDir%\data\DarkShrineEffects.txt 
        {  
            ; This loop retrieves each line from the file, one at a time.
            StringSplit, DsEffect, A_LoopReadLine, |,
            if (DsAffix = DsEffect1) {
                If ((Item.IsRing or Item.IsAmulet or Item.IsBelt or Item.IsJewel) and (DsAffix = "+# to Evasion Rating" or DsAffix = "#% Increased Evasion Rating")) {
                    ; Evasion rating on jewelry and jewels has a different effect than Evasion rating on other rares
                    Result := Result . "`n  - Always watch your back (jewelry only)`n  -- Three rare monsters spawn around the darkshrine"
                } Else If ((Item.IsJewel) and (DsAffix = "#% increased Critical Strike Chance for Spells")) {
                    ; Crit chance for spells on jewels has a different effect than on other rares
                    Result := Result . "`n  - Keeper of the wand (jewel only)`n  -- A rare monster in the area will drop five rare wands"
                } Else If ((Item.IsJewel) and (DsAffix = "#% increased Accuracy Rating")) {
                    ; Accuracy on jewels has a different effect than on other rares
                    Result := Result . "`n  - Shroud your path in the fog of war (jewel only)`n  -- Grants permanent Shrouded shrine"
                } Else If ((Item.IsRing or Item.IsAmulet or Item.IsBelt) and InStr(DsAffix,"Adds #-# Chaos Damage")) {
                    ; Flat added chaos damage on jewelry (elreon mod) has a different effect than on weapons (according to wiki)
                    Result := Result . "`n  - Feel the corruption in your veins (jewelry only)`n  -- Monsters poison on hit"
                } Else {
                    Result := Result . "`n  - " . DsEffect3 . "`n  -- " . DsEffect2
                }
                ; TODO: maybe use DsEffect 5 to display warning about complex affixes
                ; We found the affix so we can continue with the next affix
                continue affixloop
            }
        }
        
        Result := Result . "`n  - Unknown"
        
    }
      
    If (Found <= 2 and not Item.IsUnidentified) {
        Result := Result . "`n 2-affix rare:`n  - Try again`n  -- Consumes the item, Darkshrine may be used again"
    }
    
    If (ItemData.Links == 5) {
        Result := Result .  "`n 5-Linked:`n  - You win some and you lose some`n  -- Randomizes the numerical values of explicit mods on a random item"
    } Else If (ItemData.Links == 6) {
        Result := Result .  "`n 6-Linked:`n  - The ultimate gamble, but only for those who are prepared`n  -- All items on the ground are affected by an Orb of Chance"
    }
    
    
    If (Item.IsCorrupted) {
        Result := Result .  "`n Corrupted:`n  - The influence of vaal continues long after their civilization has crumbled`n  -- Opens portals to a corrupted area"
    }
    
    If (Item.Quality == 20) {
        Result := Result .  "`n 20% Quality:`n  - Wait, what was that sound?`n  -- Random item gets a skin transfer"
    }
    
    If (Item.IsMirrored) {
        Result := Result .  "`n Mirrored:`n  - The little things add up`n  -- Rerolls the implicit mod on a random item"
    }
    
    If (Item.IsUnidentified) {
        Result := Result .  "`n Unidentified:`n  - Same effect as if the item is identified first"
    }
    
    return Result
    
}

; Same as AdjustRangeForQuality, except that Value is just
; a single value and not a range.
AdjustValueForQuality(Value, ItemQuality, Direction="up")
{
    If (ItemQuality < 1)
        return Value
    Divisor := ItemQuality / 100
    If (Direction == "up")
    {
        Result := Round(Value + (Value * Divisor))
    }
    Else
    {
        Result := Round(Value - (Value * Divisor))
    }
    return Result
}

; Adjust an affix' range for +% Quality on an item.
; For example: given the range 10-20 and item quality +15%
; the result would be 11.5-23 which is currently rounded up
; to 12-23. Note that Direction does not play a part in rounding
; rather it controls if adjusting up towards quality increase or
; down from quality increase (to get the original value back)
AdjustRangeForQuality(ValueRange, ItemQuality, Direction="up")
{
    If (ItemQuality = 0)
    {
        return ValueRange
    }
    VRHi := 0
    VRLo := 0
    ParseRange(ValueRange, VRHi, VRLo)
    Divisor := ItemQuality / 100
    If (Direction == "up")
    {
        VRHi := Round(VRHi + (VRHi * Divisor))
        VRLo := Round(VRLo + (VRLo * Divisor))
    }
    Else
    {
        VRHi := Round(VRHi - (VRHi * Divisor))
        VRLo := Round(VRLo - (VRLo * Divisor))
    }
    If (VRLo == VRHi)
    {
        ValueRange = %VRLo%
    }
    Else
    {
        ValueRange = %VRLo%-%VRHi%
    }
    return ValueRange
}

; Checks ActualValue against ValueRange, returning 1 if 
; ActualValue is within bounds of ValueRange, 0 otherwise.
WithinBounds(ValueRange, ActualValue)
{
    VHi := 0
    VLo := 0
    ParseRange(ValueRange, VHi, VLo)
    Result := 1
    IfInString, ActualValue, -
    {
        AVHi := 0
        AVLo := 0
        ParseRange(ActualValue, AVHi, AVLo)
        If ((AVLo < VLo) or (AVHi > VHi))
        {
            Result := 0
        }
    }
    Else
    {
        If ((ActualValue < VLo) or (ActualValue > VHi))
        {
            Result := 0
        }
    }
    return Result
}

GetAffixTypeFromProcessedLine(PartialAffixString)
{
    Global AffixLines
    NumAffixLines := AffixLines.MaxIndex()
    Loop, %NumAffixLines%
    {
        AffixLine := AffixLines[A_Index]
        IfInString, AffixLine, %PartialAffixString%
        {
            StringSplit, AffixLineParts, AffixLine, |
            return AffixLineParts3
        }
    }
}

; Get actual value from a line of the ingame tooltip as a number
; that can be used in calculations.
GetActualValue(ActualValueLine)
{
    Result := RegExReplace(ActualValueLine, ".*?\+?(\d+(?:-\d+|\.\d+)?).*", "$1")
    return Result
}

; Get value from a colon line, e.g. given the line "Level: 57", returns the number 57
GetColonValue(Line)
{
    IfInString, Line, :
    {
        StringSplit, LineParts, Line, :
        Result := StrTrimSpace(LineParts%LineParts%2)
        return Result
    }
}

RangeMid(Range)
{
    If (Range = 0 or Range = "0" or Range = "0-0")
    {
        return 0
    }
    RHi := 0
    RLo := 0
    ParseRange(Range, RHi, RLo)
    RSum := RHi+RLo
    If (RSum == 0)
    {
        return 0
    }
    return Floor((RHi+RLo)/2)
}

RangeMin(Range)
{
    If (Range = 0 or Range = "0" or Range = "0-0")
    {
        return 0
    }
    RHi := 0
    RLo := 0
    ParseRange(Range, RHi, RLo)
    return RLo
}

RangeMax(Range)
{
    If (Range = 0 or Range = "0" or Range = "0-0")
    {
        return 0
    }
    RHi := 0
    RLo := 0
    ParseRange(Range, RHi, RLo)
    return RHi
}

AddRange(Range1, Range2)
{
    R1Hi := 0
    R1Lo := 0
    R2Hi := 0
    R2Lo := 0
    ParseRange(Range1, R1Hi, R1Lo)
    ParseRange(Range2, R2Hi, R2Lo)
    FinalHi := R1Hi + R2Hi
    FinalLo := R1Lo + R2Lo
    FinalRange = %FinalLo%-%FinalHi%
    return FinalRange
}

; Used to check return values from LookupAffixBracket()
IsValidBracket(Bracket)
{
    If (Bracket == "n/a")
    {
        return False
    }
    return True
}

; Used to check return values from LookupAffixData()
IsValidRange(Bracket)
{
    IfInString, Bracket, n/a
    {
        return False
    }
    return True
}

; Note that while ExtractCompAffixBalance() can be run on processed data
; that has compact affix type declarations (or not) for this function to
; work properly, make sure to run it on data that has compact affix types
; turned off. The reason being that it is hard to count prefixes by there
; being a "P" in a line that also has mirrored affix descriptions.
ExtractTotalAffixBalance(ProcessedData, ByRef Prefixes, ByRef Suffixes, ByRef CompPrefixes, ByRef CompSuffixes)
{
    Loop, Parse, ProcessedData, `n, `r
    {
        AffixLine := A_LoopField
        IfInString, AffixLine, Comp. Prefix
        {
            CompPrefixes += 1
        }
        IfInString, AffixLine, Comp. Suffix
        {
            CompSuffixes += 1
        }
    }
    ProcessedData := RegExReplace(ProcessedData, "Comp\. Prefix", "")
    ProcessedData := RegExReplace(ProcessedData, "Comp\. Suffix", "")
    Loop, Parse, ProcessedData, `n, `r
    {
        AffixLine := A_LoopField
        IfInString, AffixLine, Prefix
        {
            Prefixes += 1
        }
        IfInString, AffixLine, Suffix
        {
            Suffixes += 1
        }
    }
}

ExtractCompositeAffixBalance(ProcessedData, ByRef CompPrefixes, ByRef CompSuffixes)
{
    Loop, Parse, ProcessedData, `n, `r
    {
        AffixLine := A_LoopField
        IfInString, AffixLine, Comp. Prefix
        {
            CompPrefixes += 1
        }
        IfInString, AffixLine, Comp. Suffix
        {
            CompSuffixes += 1
        }
    }
}

ParseFlaskAffixes(ItemDataAffixes)
{    
    Global AffixTotals
    
    IfInString, ItemDataChunk, Unidentified
    {
        return ; Not interested in unidentified items
    }
    
    NumPrefixes := 0
    NumSuffixes := 0
    
    Loop, Parse, ItemDataAffixes, `n, `r
    {
        If StrLen(A_LoopField) = 0
        {
            Continue ; Not interested in blank lines
        }

        ; Suffixes
        
        IfInString, A_LoopField, Dispels
        {
            ; Covers Shock, Burning and Frozen and Chilled
            If (NumSuffixes < 1)
            {
                NumSuffixes += 1
            }
            Continue
        }
        IfInString, A_LoopField, Removes Bleeding
        {
            If (NumSuffixes < 1)
            {
                NumSuffixes += 1
            }
            Continue
        }
        IfInString, A_LoopField, Removes Curses on use
        {
            If (NumSuffixes < 1)
            {
                NumSuffixes += 1
            }
            Continue
        }
        IfInString, A_LoopField, during flask effect
        {
            If (NumSuffixes < 1)
            {
                NumSuffixes += 1
            }
            Continue
        }
        IfInString, A_LoopField, Adds Knockback
        {
            If (NumSuffixes < 1)
            {
                NumSuffixes += 1
            }
            Continue
        }
        IfInString, A_LoopField, Life Recovery to Minions
        {
            If (NumSuffixes < 1)
            {
                NumSuffixes += 1
            }
            Continue
        }
        
        ; Prefixes
        
        IfInString, A_LoopField, Recovery Speed
        {
            If (NumPrefixes < 1) 
            {
                NumPrefixes += 1
            }
            Continue
        }
        IfInString, A_LoopField, Amount Recovered
        {
            If (NumPrefixes < 1) 
            {
                NumPrefixes += 1
            }
            Continue
        }
        IfInString, A_LoopField, Charges
        {
            If (NumPrefixes < 1) 
            {
                NumPrefixes += 1
            }
            Continue
        }
        IfInString, A_LoopField, Instant
        {
            If (NumPrefixes < 1) 
            {
                NumPrefixes += 1
            }
            Continue
        }
        IfInString, A_LoopField, Charge when
        {
            If (NumPrefixes < 1) 
            {
                NumPrefixes += 1
            }
            Continue
        }
        IfInString, A_LoopField, Recovery when
        {
            If (NumPrefixes < 1) 
            {
                NumPrefixes += 1
            }
            Continue
        }
        IfInString, A_LoopField, Mana Recovered
        {
            If (NumPrefixes < 1) 
            {
                NumPrefixes += 1
            }
            Continue
        }
        IfInString, A_LoopField, Life Recovered
        {
            If (NumPrefixes < 1) 
            {
                NumPrefixes += 1
            }
            Continue
        }
    }
    
    AffixTotals.NumPrefixes := NumPrefixes
    AffixTotals.NumSuffixes := NumSuffixes
}

; Try looking up the remainder bracket based on Bracket
; This is done by calculating the rest value in three 
; different ways, falling through if not successful:
;
; 1) CurrValue - RangeMid(Bracket)
; 2) CurrValue - RangeMin(Bracket)
; 3) CurrValue - RangeMax(Bracket)
;
; (Internal: RegExr x-forms): 
;
; with ByRef BracketLevel:
;   ( *)(.+Rest) := CurrValue - RangeMid\((.+)\)\r *(.+) := LookupAffixBracket\((.+?), (.+?), (.+?), (.+?)\)
;   -> $1$4 := LookupRemainingAffixBracket($5, $6, CurrValue, $3, $8)
;
; w/o ByRef BracketLevel:
;   ( *)(.+Rest) := CurrValue - RangeMid\((.+)\)\r *(.+) := LookupAffixBracket\((.+?), (.+?), (.+?)\)
;   -> $1$4 := LookupRemainingAffixBracket($5, $6, CurrValue, $3)
;
LookupRemainingAffixBracket(Filename, ItemLevel, CurrValue, Bracket, ByRef BracketLevel=0)
{
    RestValue := CurrValue - RangeMid(Bracket)
    RemainderBracket := LookupAffixBracket(Filename, ItemLevel, RestValue, BracketLevel)
    If (Not IsValidBracket(RemainderBracket))
    {
        RestValue := CurrValue - RangeMin(Bracket)
        RemainderBracket := LookupAffixBracket(Filename, ItemLevel, RestValue, BracketLevel)
    }
    If (Not IsValidBracket(RemainderBracket))
    {
        RestValue := CurrValue - RangeMax(Bracket)
        RemainderBracket := LookupAffixBracket(Filename, ItemLevel, RestValue, BracketLevel)
    }
    return RemainderBracket
}


#Include %A_ScriptDir%\lib\functions\ParseAffixes.ahk


; Change a detail line that was already processed and added to the 
; AffixLines "stack". This can be used for example to change the
; affix type when more is known about a possible affix combo. 
;
; For example with a IPD / AR combo, if IPD was thought to be a
; Prefix but later (when processing AR) found to be a Composite
; Prefix.
ChangeAffixDetailLine(PartialAffixString, SearchRegex, ReplaceRegex)
{
    Global AffixLines
    NumAffixLines := AffixLines.MaxIndex()
    Loop, %NumAffixLines%
    {
        CurAffixLine := AffixLines[A_Index]
        IfInString, CurAffixLine, %PartialAffixString%
        {
            NewLine := RegExReplace(CurAffixLine, SearchRegex, ReplaceRegex)
            AffixLines.Set(A_Index, NewLine)
            return True
        }
    }
    return False
}

ExtractValueFromAffixLine(ItemDataChunk, PartialAffixString)
{
    Loop, Parse, ItemDataChunk, `n, `r
    {
        If StrLen(A_LoopField) = 0
        {
            Break ; Not interested in blank lines
        }
        IfInString, ItemDataChunk, Unidentified
        {
            Break ; Not interested in unidentified items
        }

        CurrValue := GetActualValue(A_LoopField)

        IfInString, A_LoopField, %PartialAffixString%
        {
            return CurrValue
        }
    }
}

ResetAffixDetailVars()
{
    Global AffixLines, AffixTotals, Globals
    AffixLines.Reset()
    AffixTotals.Reset()
    Globals.Set("MarkedAsGuess", False)
}

IsEmptyString(String)
{
    If (StrLen(String) == 0)
    {
        return True
    }
    Else
    {
        String := RegExReplace(String, "[\r\n ]", "")
        If (StrLen(String) < 1)
        {
            return True
        }
    }
    return False
}

PreProcessContents(CBContents)
{
    ; --- Place fixes for data inconsistencies here ---

    ; Remove the line that indicates an item cannot be used due to missing character stats
    Needle := "You cannot use this item. Its stats will be ignored. Please remove it.`r`n--------`r`n"
    StringReplace, CBContents, CBContents, %Needle%, 
    ; Replace double seperator lines with one seperator line
    Needle := "--------`r`n--------`r`n"
    StringReplace, CBContents, CBContents, %Needle%, --------`r`n, All
    
    return CBContents
}

PostProcessData(ParsedData)
{
    Global Opts
    
    Result := ParsedData
    If (Opts.CompactAffixTypes > 0)
    {
        StringReplace, TempResult, ParsedData, --------`n, ``, All  
        StringSplit, ParsedDataChunks, TempResult, ``
        
        Result =
        Loop, %ParsedDataChunks0%
        {
            CurrChunk := ParsedDataChunks%A_Index%
            If IsEmptyString(CurrChunk)
            {
                Continue
            }
            If (InStr(CurrChunk, "Comp.") and Not InStr(CurrChunk, "Affixes"))
            {
                CurrChunk := RegExReplace(CurrChunk, "Comp\. ", "C")
            }
            If (InStr(CurrChunk, "Suffix") and Not InStr(CurrChunk, "Affixes"))
            {
                CurrChunk := RegExReplace(CurrChunk, "Suffix", "S")
            }
            If (InStr(CurrChunk, "Prefix") and Not InStr(CurrChunk, "Affixes"))
            {
                CurrChunk := RegExReplace(CurrChunk, "Prefix", "P")
            }
            If (A_Index < ParsedDataChunks0)
            {
                Result := Result . CurrChunk . "--------`r`n"
            }
            Else
            {
                Result := Result . CurrChunk
            }
        }
    }
    return Result
}

ParseClipBoardChanges()
{
    Global Opts, Globals

    CBContents := GetClipboardContents()
    CBContents := PreProcessContents(CBContents)

    Globals.Set("ItemText", CBContents)
    
    If (GetKeyState("Shift"))
    {
        Globals.Set("TierRelativeToItemLevelOverride", !Opts.TierRelativeToItemLevel)
    }
    Else
    {
        Globals.Set("TierRelativeToItemLevelOverride", Opts.TierRelativeToItemLevel)
    }

    ParsedData := ParseItemData(CBContents)
    ParsedData := PostProcessData(ParsedData)

    If (Opts.PutResultsOnClipboard > 0)
    {
        SetClipboardContents(ParsedData)
    }
    ShowToolTip(ParsedData)
}

AssembleDamageDetails(FullItemData)
{
    PhysLo := 0
    PhysHi := 0
    Quality := 0
    AttackSpeed := 0
    PhysMult := 0
    ChaoLo := 0
    ChaoHi := 0
    ColdLo := 0
    ColdHi := 0
    FireLo := 0
    FireHi := 0
    LighLo := 0
    LighHi := 0

    Loop, Parse, FullItemData, `n, `r
    {        
        ; Get quality
        IfInString, A_LoopField, Quality:
        {
            StringSplit, Arr, A_LoopField, %A_Space%, +`%
            Quality := Arr2
            Continue
        }
        
        ; Get total physical damage
        IfInString, A_LoopField, Physical Damage:
        {
            StringSplit, Arr, A_LoopField, %A_Space%
            StringSplit, Arr, Arr3, -
            PhysLo := Arr1
            PhysHi := Arr2
            Continue
        }
        
        ; Fix for Elemental damage only weapons. Like the Oro's Sacrifice
        IfInString, A_LoopField, Elemental Damage:
        {
            Continue
        }

        ; Get attack speed
        IfInString, A_LoopField, Attacks per Second:
        {
            StringSplit, Arr, A_LoopField, %A_Space%
            AttackSpeed := Arr4
            Continue
        }
        
        ; Get percentage physical damage increase
        IfInString, A_LoopField, increased Physical Damage
        {
            StringSplit, Arr, A_LoopField, %A_Space%, `%
            PhysMult := Arr1
            Continue
        }
        
        ; Lines to skip fix for converted type damage. Like the Voltaxic Rift
        IfInString, A_LoopField, Converted to
            Goto, SkipDamageParse
        IfInString, A_LoopField, can Shock
            Goto, SkipDamageParse

        ; Slinkston Edit. Lines to skip ele damage to spells being added.   
        IfInString, A_LoopField, %DmgType% Damage to Spells
            Goto, SkipDamageParse
        ; Lines to skip for weapons that alter damage based on if equipped as
        ; main or off hand. In that case skipp the off hand calc and just use
        ; main hand as determining factor. Examples: Dyadus, Wings of Entropy
        IfInString, A_LoopField, in Off Hand
            Goto, SkipDamageParse

        ; Parse elemental damage
        ParseElementalDamage(A_LoopField, "Chaos", ChaoLo, ChaoHi)
        ParseElementalDamage(A_LoopField, "Cold", ColdLo, ColdHi)
        ParseElementalDamage(A_LoopField, "Fire", FireLo, FireHi)
        ParseElementalDamage(A_LoopField, "Lightning", LighLo, LighHi)
        
        SkipDamageParse:
            DoNothing := True
    }
    
    Result =

    SetFormat, FloatFast, 5.1
    PhysDps := ((PhysLo + PhysHi) / 2) * AttackSpeed
    EleDps := ((ChaoLo + ChaoHi + ColdLo + ColdHi + FireLo + FireHi + LighLo + LighHi) / 2) * AttackSpeed
    TotalDps := PhysDps + EleDps
    
    Result = %Result%`nPhys DPS:   %PhysDps%`nElem DPS:   %EleDps%`nTotal DPS:  %TotalDps%
    
    ; Only show Q20 values if item is not Q20
    If (Quality < 20) {
        TotalPhysMult := (PhysMult + Quality + 100) / 100
        BasePhysDps := PhysDps / TotalPhysMult
        Q20Dps := BasePhysDps * ((PhysMult + 120) / 100) + EleDps
        
        Result = %Result%`nQ20 DPS:    %Q20Dps%
    }

    return Result
}

; ParseItemName fixed by user: uldo_.  Thanks!
ParseItemName(ItemDataChunk, ByRef ItemName, ByRef ItemTypeName)
{
    Loop, Parse, ItemDataChunk, `n, `r
    {
    If (A_Index == 1)
    {
        IfNotInString, A_LoopField, Rarity:
        {
        return
        }
        Else
        {
            Continue
        }
    }
        If (StrLen(A_LoopField) == 0 or A_LoopField == "--------" or A_Index > 3)
        {
        return
        }
    If (A_Index = 2)
    {
        If InStr(A_LoopField, ">>")
        {
        StringGetPos, pos, A_LoopField, >>, R
        ItemName := SubStr(A_LoopField, pos+3)
        }
        else
        {
            ItemName := A_LoopField
        }
    }
    If (A_Index = 3)
    {
        ItemTypeName := A_LoopField
    }
    }
}

GemIsValuable(ItemName)
{
    Loop, Read, %A_ScriptDir%\data\ValuableGems.txt
    {
        Line := StripLineCommentRight(A_LoopReadLine)
        If (SkipLine(Line))
        {
            Continue
        }
        IfInString, ItemName, %Line%
        {
            return True
        }
    }
    return False
}

UniqueIsValuable(ItemName)
{
    Loop, Read, %A_ScriptDir%\data\ValuableUniques.txt
    {
        Line := StripLineCommentRight(A_LoopReadLine)
        If (SkipLine(Line))
        {
            Continue
        }
        IfInString, ItemName, %Line%
        {
            return True
        }
    }
    return False
}

GemIsDropOnly(ItemName)
{
    Loop, Read, %A_ScriptDir%\data\DropOnlyGems.txt
    {
        Line := StripLineCommentRight(A_LoopReadLine)
        If (SkipLine(Line))
        {
            Continue
        }
        IfInString, ItemName, %Line%
        {
            return True
        }
    }
    return False
}

ParseLinks(ItemDataText)
{
    HighestLink := 0
    Loop, Parse, ItemDataText, `n, `r
    {
        IfInString, A_LoopField, Sockets
        {
            LinksString := GetColonValue(A_LoopField)
            If (RegExMatch(LinksString, ".-.-.-.-.-."))
            {
                HighestLink := 6
                Break
            }
            If (RegExMatch(LinksString, ".-.-.-.-."))
            {
                HighestLink := 5
                Break
            }
            If (RegExMatch(LinksString, ".-.-.-."))
            {
                HighestLink := 4
                Break
            }
            If (RegExMatch(LinksString, ".-.-."))
            {
                HighestLink := 3
                Break
            }
            If (RegExMatch(LinksString, ".-."))
            {
                HighestLink := 2
                Break
            }
        }
    }
    return HighestLink
}

; TODO: find a way to poll this date from the web!

; Converts a currency stack to Chaos by looking up the 
; conversion ratio from CurrencyRates.txt
ConvertCurrency(ItemName, ItemStats)
{
    If (InStr(ItemName, "Shard"))
    {
        IsShard := True
        ItemName := "Orb of " . SubStr(ItemName, 1, -StrLen(" Shard"))
    }
    If (InStr(ItemName, "Fragment"))
    {
        IsFragment := True
        ItemName := "Scroll of Wisdom"
    }
    StackSize := SubStr(ItemStats, StrLen("Stack Size:  "))
    StringSplit, StackSizeParts, StackSize, /
    If (IsShard or IsFragment)
    {
        SetFormat, FloatFast, 5.3
        StackSize := StackSizeParts1 / StackSizeParts2
    }
    Else
    {
        SetFormat, FloatFast, 5.2
        StackSize := StackSizeParts1
    }
    ValueInChaos := 0
    Loop, Read, %A_ScriptDir%\data\CurrencyRates.txt
    {
        Line := StripLineCommentRight(A_LoopReadLine)
        If (SkipLine(Line))
        {
            Continue
        }
        IfInString, Line, %ItemName%
        {
            StringSplit, LineParts, Line, |
            ChaosRatio := LineParts2
            StringSplit, ChaosRatioParts,ChaosRatio, :
            ChaosMult := ChaosRatioParts2 / ChaosRatioParts1
            ValueInChaos := (ChaosMult * StackSize)
            return ValueInChaos
        }
    }
    return ValueInChaos
}

FindUnique(ItemName)
{
    Loop, Read, %A_ScriptDir%\data\Uniques.txt
    {
        Line := StripLineCommentRight(A_LoopReadLine)
        If (SkipLine(Line))
        {
            Continue
        }
        IfInString, Line, %ItemName%
        {
            return True
        }
    }
    return False
}

; Strip comments at line end, e.g. "Bla bla bla ; comment" -> "Bla bla bla"
StripLineCommentRight(Line)
{
    IfNotInString, Line, `;
    {
        return Line
    }
    ProcessedLine := RegExReplace(Line, "(.+?)([ \t]*;.+)", "$1")
    If IsEmptyString(ProcessedLine)
    {
        return Line
    }
    return ProcessedLine
}

; Return True if line begins with comment character (;)
; or if it is blank (that is, it only has 2 characters
; at most (newline and carriage return)
SkipLine(Line)
{
    IfInString, Line, `;
    {
        ; Comment
        return True
    }
    If (StrLen(Line) <= 2)
    {
        ; Blank line (at most \r\n)
        return True
    }
    return False
}

; Parse unique affixes from text file database.
; Has wanted side effect of populating AffixLines "array" vars.
; return True if the unique was found the database
ParseUnique(ItemName)
{
    Global Opts, AffixLines
    
    Delim := "|"
    ResetAffixDetailVars()
    UniqueFound := False
    Loop, Read, %A_ScriptDir%\data\Uniques.txt
    {
        ALine := StripLineCommentRight(A_LoopReadLine)
        If (SkipLine(ALine))
        {
            Continue
        }
        IfInString, ALine, %ItemName%
        {
            StringSplit, LineParts, ALine, |
            NumLineParts := LineParts0
            NumAffixLines := NumLineParts-1 ; exclude item name at first pos
            UniqueFound := True
            AppendImplicitSep := False
            Idx := 1
            If (Opts.ShowAffixDetails == False)
            {
                return UniqueFound
            }
            Loop, % (NumLineParts)
            {
                If (A_Index > 1)
                {
                    ProcessedLine =
                    CurLinePart := LineParts%A_Index%
                    IfInString, CurLinePart, :
                    {
                        StringSplit, CurLineParts, CurLinePart, :
                        AffixLine := CurLineParts2
                        ValueRange := CurLineParts1
                        IfInString, ValueRange, @
                        {
                            AppendImplicitSep := True
                            StringReplace, ValueRange, ValueRange, @
                        }
                        ; Make "Attacks per Second" float ranges to be like a double range.
                        ; Since a 2 decimal precision float value is 4 chars wide (#.##)
                        ; when including the radix point this means a float value range 
                        ; is then 9 chars wide. Replacing the "-" with a "," effectively
                        ; makes it so that float ranges are treated as double ranges and
                        ; distributes the bounds over both value range fields. This may 
                        ; or may not be desirable. On the plus side things will align
                        ; nicely, but on the negative side, it will be a bit unclearer that
                        ; both float values constitute a range and not two isolated values.
                        ;ValueRange := RegExReplace(ValueRange, "(\d+\.\d+)-(\d+\.\d+)", "$1,$2") ; DISABLED for now
                        IfInString, ValueRange, `,
                        {
                            ; Double range
                            StringSplit, VRParts, ValueRange, `,
                            LowerBound := VRParts1
                            UpperBound := VRParts2
                            StringSplit, LowerBoundParts, LowerBound, -
                            StringSplit, UpperBoundParts, UpperBound, -
                            LBMin := LowerBoundParts1
                            LBMax := LowerBoundParts2
                            UBMin := UpperBoundParts1
                            UBMax := UpperBoundParts2
                            If (Opts.CompactDoubleRanges) 
                            {
                                ValueRange := StrPad(LBMin . "-" . UBMax, Opts.ValueRangeFieldWidth, "left")
                            }
                            Else
                            {
                                ValueRange := StrPad(LowerBound, Opts.ValueRangeFieldWidth, "left") . Opts.AffixDetailDelimiter . StrPad(UpperBound, Opts.ValueRangeFieldWidth, "left")
                            }
                        }
                        ProcessedLine := AffixLine . Delim . StrPad(ValueRange, Opts.ValueRangeFieldWidth, "left")
                        If (AppendImplicitSep)
                        {
                            ProcessedLine := ProcessedLine . "`n" . "--------"
                            AppendImplicitSep := False
                        }
                        AffixLines.Set(Idx, ProcessedLine)
                    }
                    Else
                    {
                        AffixLines.Set(Idx, CurLinePart)
                    }
                    Idx += 1
                }
            }
            return UniqueFound
        }
    }
    return UniqueFound
}

ItemIsMirrored(ItemDataText)
{
    Loop, Parse, ItemDataText, `n, `r
    {
        If (A_LoopField == "Mirrored")
        {
            return True
        }
    }
    return False
}

#Include %A_ScriptDir%\lib\functions\ParseItemData.ahk

GetNegativeAffixOffset(Item)
{
    NegativeAffixOffset := 0
    If (Item.IsFlask or Item.IsUnique or Item.IsTalisman)
    {
        ; Uniques as well as flasks have descriptive text as last item,
        ; so decrement item index to get to the item before last one
        NegativeAffixOffset := NegativeAffixOffset + 1
    }
    If (Item.IsMap) 
    {
        ; Maps have a descriptive text as the last item
        NegativeAffixOffset := NegativeAffixOffset + 1
    }
    If (Item.IsJewel) 
    {
        ; Jewels, like maps and flask, have a descriptive text as the last item
        NegativeAffixOffset := NegativeAffixOffset + 1
    }
    If (Item.HasEffect) 
    {
        ; Same with weapon skins or other effects
        NegativeAffixOffset := NegativeAffixOffset + 1
    }
    If (Item.IsCorrupted) 
    {
        ; And corrupted items
        NegativeAffixOffset := NegativeAffixOffset + 1
    }
    If (Item.IsMirrored) 
    {
        ; And mirrored items
        NegativeAffixOffset := NegativeAffixOffset + 1
    }
    
    return NegativeAffixOffset
}

; Don't use! Not working correctly yet!
ExtractRareItemTypeName(ItemName)
{
    ItemTypeName := RegExReplace(ItemName, "(.+?) (.+) of (.+)", "$2")
    return ItemTypeName
}

; Show tooltip, with fixed width font
ShowToolTip(String)
{
    Global X, Y, ToolTipTimeout, Opts
    
    ; Get position of mouse cursor
    MouseGetPos, X, Y

    If (Not Opts.DisplayToolTipAtFixedCoords) 
    {
        ToolTip, %String%, X - 135, Y + 35
    Fonts.SetFixedFont()
    ToolTip, %String%, X - 135, Y + 35
    }
    Else
    {
        CoordMode, ToolTip, Screen
        ;~ GetScreenInfo()
        ;~ TotalScreenWidth := Globals.Get("TotalScreenWidth", 0)
        ;~ HalfWidth := Round(TotalScreenWidth / 2)
        
        ;~ SecondMonitorTopLeftX := HalfWidth
        ;~ SecondMonitorTopLeftY := 0
        ScreenOffsetY := Opts.ScreenOffsetY
        ScreenOffsetX := Opts.ScreenOffsetX
        
        XCoord := 0 + ScreenOffsetX
        YCoord := 0 + ScreenOffsetY
        
        ToolTip, %String%, XCoord, YCoord
    Fonts.SetFixedFont()
    ToolTip, %String%, XCoord, YCoord
    }    
    ;Fonts.SetFixedFont()
    
    ; Set up count variable and start timer for tooltip timeout
    ToolTipTimeout := 0
    SetTimer, ToolTipTimer, 100
}