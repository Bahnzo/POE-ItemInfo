; Path of Exile Item Info Tooltip
;
; Version: 1.9.2 (hazydoc / IGN:Sadou) Original Author
; Script is currently maintained by various people and kept up to date by Bahnzo / IGN:Bahnzo
; This script was originally based on the POE_iLVL_DPS-Revealer script (v1.2d) found here:
; https://www.pathofexile.com/forum/view-thread/594346
; New Thread: https://www.pathofexile.com/forum/view-thread/790438
;
; Changes to the POE_iLVL_DPS-Revealer script as recent as it's version 1.4.1 have been 
; brought over. Thank you Nipper4369 and Kislorod!
;
; The script has been added to substantially to enable the following features in addition to 
; itemlevel and weapon DPS reveal:
;
;   - show total affix statistic for rare items
;   - show possible min-max ranges for all affixes on rare items
;   - reveal the combination of difficult compound affixes (you might be surprised what you find)
;   - show affix ranges for uniques
;   - show map info (thank you, Kislorod and Necrolis)
;   - show max socket info (thank you, Necrolis)
;   - has the ability to convert currency items to chaos orbs (you can adjust the rates by editing
;     <datadir>\CurrencyRates.txt)
;   - can show which gems are valuable and/or drop-only (all user adjustable)
;   - can show a reminder for uniques that are generally considered valuable (user adjustable as well)
;   - adds a system tray icon and proper system tray description tooltip
;
; All of these features are user-adjustable by using a "database" of text files which come 
; with the script and are easy to edit by non developers. See header comments in those files
; for format infos and data sources.
;
; Known issues:
;     
;     Even though there have been tons of tests made on composite affix combinations, I expect
;     there to be edge cases still that may return an invalid or not found affix bracket.
;     You can see these entries in the affix detail lines if they have the text "n/a" (not available)
;     somewhere in them or if you see an empty range " - *". The star by the way marks ranges
;     that have been added together for a guessed attempt as to the composition of a possible 
;     compound affix. If you see this star, take a closer look for a moment to check if the 
;     projection is correct. I expect these edge cases to be properly dealt with over time as the
;     script matures. For now I'd estimate that at least 80% of the truly hard cases are correctly 
;     identified.
;
;     Some background info: because the game concatenates values from multiple affix sources into
;     one final entry on the ingame tooltip there is no reliable way to work backwards from the 
;     composite value to each individual part. For example, Stun Recovery can be added as suffix if 
;     it contributes alone, but can also be a prefix if it is a composite of Stun Recovery and
;     Evasion Rating (or others). Because there is one final entry, while prefix and suffix can
;     appear at the same time and will be added together, you can't reliably reverse engineer which 
;     affix contributed what part of the composite value. This is akin to taking a random source of
;     numbers, adding them up to one value and then asking someone to work out backwards what the 
;     original source values were.
;     Similarily, in cases like boosted Stun Recovery (1) and Evasion Rating (2) on an item in difficult
;     cases there is no 100% reliable way to tell if the prefix "+ Evasion Rating / incr. Stun Recovery" 
;     contributed to both stats at once or if the suffix "+ Stun Recovery" contributed to (1) 
;     and the prefix "+ Evasion Rating" cotributed to (2) or possibly a combination of both. 
;     Often it is possible to make guesses by working your way backwards from both partial affixes, by
;     looking at the affix bracket ranges and the item level to see what is even possible to be there and
;     what isn't. In the worst case for a double compound affix, all four ranges will be possible to be
;     combined.
;
;     I have tested the tooltip on many, many items in game from my own stash and from trade chat
;     and I can say that in the overwhelming majority of cases the tooltip does indeed work correctly.
;
;     IMPORTANT: as you may know, the total amount of affixes (w/o implicit mods) can be 6, of which
;     3 at most are prefixes and likewise 3 at most are suffixes. Be especially weary, then of cases
;     where this prefix/suffix limit is overcapped. It may happen that the tooltip shows 4 suffixes,
;     and 3 prefixes total. In this case the most likely explanation is that the script failed to properly
;     determine composite affixes. Composite affixes ("Comp. Prefix" or "Comp. Suffix" in the tooltip)
;     are two affix lines on the ingame tooltip that together form one single composite affix. 
;     Edit v1.4: This hasn't happened for a longer time now, but I am leaving this important note in
;     so end users stay vigilant (assuming anyone even reads this wall of text :)).
;
;   - I do not know which affixes are affected by +% Item Quality. Currently I have functions in place 
;     that can boost a range or a single value to adjust for Item Quality but currently these aren't used
;     much. Partially this is also because it is not easy to tell if out-of-bounds cases are the result
;     of faulty input data (I initially pulled data from the PoE mods compendium but later made the PoE
;     homepage the authoritative source overruling data from other sources) or of other unreckognized and
;     unhandled entities or systems.
;
; Todo:
;
;   - handle ranges for implicit mods
;   - find a way to deal with master crafted mods (currently that's a tough one, probably won't be possible)
;   - show max possible for guesstimated ranges
;   - de-globalize the script (almost done)
;   - refactor ParseAffixes into ParseAffixesSimple and ParseAffixesComplex (low priority)
; 
; Slinkston edit for Todo for 2.0 additions for hazydoc or someone else knowledgable in coding:
;	- FYI: All of the stuff I have edited has been marked with ; Slinkston edit.  Some may need to be cleaned up or redone if
;	  they are done improperly/sloppy.  I have tested all changes with stuff in my stash and with friends, but not every single possibility.
;	- Accuracy is a nightmare.  Anyhow, "of the Assassin - 321 to 360 Accuracy (80) (Bow and Wand)" needs
;	  to be addressed for 2.0 or not /shrug.  I have passed on the request to GGG to perhaps mark up their affixes so they are decipherable.
;	- Uniques need to be updated.  Apparently poe_scrape.py has an error and is unable to run until fixed.
;	- Valuable Gems and Valuable Uniques needs to be updated as well.  Will work on this keeping in mind both default leagues and temp leagues
;	- Divination card info would be great such as a) what you can possibly get for the collection, b) where that card drops, and c) what supporter 
;	  created it (if known).
;	- Jewel support for min/max rolls and what is a suffix and what is a prefix so you know what you may be able to exalt.  9/15/2015 - I just noticed that
;	  GGG added jewel affixes, both prefix and suffix, for jewels to their item database.
;	- Legacy item alert on the item would be useful for those players that take breaks and come back without reading all the patch notes and/or
;	  not recognizing some item may have changed or not.  This alert can be placed along the bottom with 'quality, valuable, mirrored, etc.'
;	  I imagine that this would not be hard to do, but would require a lot of small detail work.  Because all uniques are nerfed/buffed in 
;	  specific ways, there is no 'quick' and easy way to do this.  There would have to be a specific check for each specific unique item looking 
;	  at the particular change(s) and compare it to the existing known unique setup vs the legacy setup.  I would be willing to do all the small
;	  detail work required for each unique if someone would write the code required for this to work and how this would work with the current unique.txt
;	  list.  This is obviously less valuable of an addition to the PoE-Item-Info script than general upgrades/div cards/jewel support.
;
; Notes:
;
;   - Global values marked with an inline comment "d" are globals for debugging so they can be easily 
;     (re-)enabled using global search and replace. Marking variables as global means they will show 
;     up in AHK's Variables and contents view of the script.
;   
; Needs AutoHotKey v1.1.05 or later 
;   from http://ahkscript.org and NOT http://www.autohotkey.com
;   the latter domain was apparently taken over by a for-profit company!
;
; Original credits:
;
;   mcpower - for the base iLVL display of the script 5months ago before Immo.
;   Immo - for the base iLVL display of the script.(Which was taken from mcpower.)
;   olop4444 - for helping me figure out the calculations for Q20 items.
;   Aeons - for a rewrite and fancy tooltips.
;   kongyuyu - for base item level display.
;   Fayted - for testing the script.
;
; Original author's comment:
;
; If you have any questions or comments please post them there as well. If you think you can help
; improve this project. I am looking for contributors. So Pm me if you think you can help.
;
; If you have a issue please post what version you are using.
; Reason being is that something that might be a issue might already be fixed.
;

; Run test suites (see end of script)
; Note: don't set this to true for normal every day use...
; This is just for fellow developers. 
RunTests := False

#SingleInstance force
#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#Persistent ; Stay open in background
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.
#Include %A_ScriptDir%\data\Version.txt

MsgWrongAHKVersion := "AutoHotkey v" . AHKVersionRequired . " or later is needed to run this script. `n`nYou are using AutoHotkey v" . A_AhkVersion . " (installed at: " . A_AhkPath . ")`n`nPlease go to http://ahkscript.org to download the most recent version."
If (A_AhkVersion <= AHKVersionRequired)
{
    MsgBox, 16, Wrong AutoHotkey Version, % MsgWrongAHKVersion
    ExitApp
}

#Include %A_ScriptDir%\data\Messages.txt

#Include lib\globals.ahk

#Include lib\classes.ahk

IfNotExist, %A_ScriptDir%\config.ini
{
    IfNotExist, %A_ScriptDir%\data\defaults.ini
    {
        CreateDefaultConfig()
    }
    CopyDefaultConfig()
}

#Include lib\menu.ahk

IfNotExist, %A_ScriptDir%\data
{
    MsgBox, 16, % Msg.DataDirNotFound
    exit
}

#Include %A_ScriptDir%\data\MapList.txt

Fonts.Init(Opts.FontSize, 9)

#Include lib\functions.ahk

#Include lib\tests.ahk

#Include lib\gui.ahk

#Include lib\settings.ahk

#Include lib\timers.ahk

; ############ ADD YOUR OWN MACROS HERE #############
;#IfWinActive Path of Exile ahk_class Direct3DWindowClass ahk_exe PathOfExile.exe
;{
;   ^RButton::Send ^c   ;cntl-right mouse button send's cntl-c
;   ^WheelUp::Send {Left}  ;cntl-mouse wheel up toggles stash tabs left
;   ^WheelDown::Send {Right}  ;cntl-mouse wheel down toggles stash tabs right.
;   F1::^c  ;changes the control-c to F1 key
;	F5::Send {Enter}/remaining{Enter}  	;mobs remaining
;	F9::Send {Enter}/hideout{Enter}		;goto hideout
;	F10::Send {Enter}/global 666{Enter}	;join a channel
;} ;*/
