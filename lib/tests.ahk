; ############## TESTS #################

Globals.Set("TestCaseSeparator", "####################")

RunRareTestSuite(Path, SuiteNumber)
{
    Global AffixTotals
    
    NumTestCases := 0
    Loop, Read, %Path%
    {  
        IfInString, A_LoopReadLine, % Globals.TestCaseSeparator
        {
            NumTestCases += 1
            Continue
        }
        TestCaseText := A_LoopReadLine
        TestCases%NumTestCases% := TestCases%NumTestCases% . TestCaseText . "`r`n"
    }

    Failures := 0
    Successes := 0
    FailureNumbers =
    TestCase =
    Loop, %NumTestCases%
    {
        TestCase := TestCases%A_Index%

        RarityLevel := 0
        TestCaseResult := ParseItemData(TestCase, RarityLevel)
        NumPrefixes := AffixTotals.NumPrefixes
        NumSuffixes := AffixTotals.NumSuffixes

        StringReplace, TempResult, TestCaseResult, --------, ``, All  
        StringSplit, TestCaseResultParts, TempResult, ``

        NameAndDPSPart := TestCaseResultParts1
        TotalAffixStatsPart := TestCaseResultParts2
        AffixCompositionPart := TestCaseResultParts3

        ; failure conditions
        TotalAffixes := 0
        TotalAffixes := NumPrefixes + NumSuffixes
        InvalidTotalAffixNumber := (TotalAffixes > 6)
        BracketLookupFailed := InStr(TestCaseResult, "n/a")
        CompositeRangeCalcFailed := InStr(TestCaseResult, " - ")

        Prefixes := 0
        Suffixes := 0
        CompPrefixes := 0
        CompSuffixes := 0
        ExtractTotalAffixBalance(AffixCompositionPart, Prefixes, Suffixes, CompPrefixes, CompSuffixes)

        HasDanglingComposites := False
        If (Mod(CompPrefixes, 2)) ; True, if not evenly divisible by 2
        {
            HasDanglingComposites := True
        }
        If (Mod(CompSuffixes, 2))
        {
            HasDanglingComposites := True
        }

        TotalCountByAffixTypes := (Floor(CompPrefixes / 2) + Floor(CompSuffixes / 2) + Prefixes + Suffixes)

        AffixTypesCountedIncorrectly := (Not (TotalCountByAffixTypes == TotalAffixes))
        If (InvalidTotalAffixNumber or BracketLookupFailed or CompositeRangeCalcFailed or HasDanglingComposites or AffixTypesCountedIncorrectly)
        {
            Failures += 1
            FailureNumbers := FailureNumbers . A_Index . ","
        }
        Else
        {
            Successes += 1
        }
        ; needed so global variables can be yanked from memory and reset between calls 
        ; (if you reload the script really fast globals vars that are out of date can 
        ; cause failures when there are none)
        Sleep, 1
    }

    Result := "Suite " . SuiteNumber . ": " . StrPad(Successes, 5, "left") . " OK" . ", " . StrPad(Failures, 5, "left")  . " Failed"
    If (Failures > 0)
    {
        FailureNumbers := SubStr(FailureNumbers, 1, -1)
        Result := Result . " (" . FailureNumbers . ")"
    }
    return Result
}

RunUniqueTestSuite(Path, SuiteNumber)
{
    Global AffixTotals
    
    NumTestCases := 0
    Loop, Read, %Path%
    {  
        IfInString, A_LoopReadLine, % Globals.TestCaseSeparator
        {
            NumTestCases += 1
            Continue
        }
        TestCaseText := A_LoopReadLine
        TestCases%NumTestCases% := TestCases%NumTestCases% . TestCaseText . "`r`n"
    }

    Failures := 0
    Successes := 0
    FailureNumbers =
    TestCase =
    Loop, %NumTestCases%
    {
        TestCase := TestCases%A_Index%
        TestCaseResult := ParseItemData(TestCase)

        FailedToSepImplicit := InStr(TestCaseResult, "@")  ; failed to properly seperate implicit from normal affixes
        ; TODO: add more unique item test failure conditions

        If (FailedToSepImplicit)
        {
            Failures += 1
            FailureNumbers := FailureNumbers . A_Index . ","
        }
        Else
        {
            Successes += 1
        }
        ; needed so global variables can be yanked from memory and reset between calls 
        ; (if you reload the script really fast globals vars that are out of date can 
        ; cause failures where there are none)
        Sleep, 1
    }

    Result := "Suite " . SuiteNumber . ": " . StrPad(Successes, 5, "left") . " OK" . ", " . StrPad(Failures, 5, "left")  . " Failed"
    If (Failures > 0)
    {
        FailureNumbers := SubStr(FailureNumbers, 1, -1)
        Result := Result . " (" . FailureNumbers . ")"
    }
    return Result
}

RunAllTests()
{
    ; change this to the number of available test suites
    TestDataBasePath = %A_ScriptDir%\extras\tests

    NumRareTestSuites := 5
    RareResults := "Rare Items"
    Loop, %NumRareTestSuites%
    {
        If (A_Index > 0) ; change condition to only run certain tests
        {
            TestSuitePath = %TestDataBasePath%\Rares%A_Index%.txt
            TestSuiteResult := RunRareTestSuite(TestSuitePath, A_Index)
            RareResults := RareResults . "`n    " . TestSuiteResult
        }
    }

    NumUniqueTestSuites := 1
    UniqResults := "Unique Items"
    Loop, %NumUniqueTestSuites%
    {
        If (A_Index > 0) ; change condition to only run certain tests
        {
            TestSuitePath = %TestDataBasePath%\Uniques%A_Index%.txt
            TestSuiteResult := RunUniqueTestSuite(TestSuitePath, A_Index)
            UniqResults := UniqResults . "`n    " . TestSuiteResult
        }
    }

    MsgBox, %RareResults%`n`n%UniqResults%
}

; ########### TESTS ############

If (RunTests)
{
    RunAllTests()
}