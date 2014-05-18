;-==============================================================================
;          File: autohotkey.ahk
;        Author: Pedro Ferrari
;       Created: 09 Apr 2014
; Last Modified: 18 May 2014
;   Description: Autohotkey configuration file
;===============================================================================
; Preamble {{{

#NoEnv
#NoTrayIcon
SendMode Input
SetTitleMatchMode, 2   ; Window title can contain WinTitle anywhere

; Reload this script
^#r::
    Msgbox, 4,, Do you want to reload autohotkey script?
    IfMsgBox Yes
    {
        Reload
    }
    Return

 ; }}}
; Window handling {{{

LeftHalfWindow()
{
	SysGet, area, MonitorWorkArea
	w:=((areaRight-areaLeft)/2)
	h:=(areaBottom-areaTop)

	WinRestore, A
	WinMove, A, , 0, 0,%w%,%h%
}

RightHalfWindow()
{
	SysGet, area, MonitorWorkArea
	w:=((areaRight-areaLeft)/2)
	h:=(areaBottom-areaTop)

	WinRestore, A
	WinMove, A, , w, 0, w, h
}

TopHalfWindow()
{
	SysGet, area, MonitorWorkArea
	w:=(areaRight-areaLeft)
	h:=((areaBottom-areaTop)/2)

	WinRestore, A
	WinMove, A, , 0, 0, w, h
}

BottomHalfWindow()
{
	SysGet, area, MonitorWorkArea
	w:=(areaRight-areaLeft)
	h:=((areaBottom-areaTop)/2)

	WinRestore, A
	WinMove, A, , 0, h, w, h
}

TopLeftQuarterfWindow()
{
	SysGet, area, MonitorWorkArea
	w:=((areaRight-areaLeft)/2)
	h:=((areaBottom-areaTop)/2)

	WinRestore, A
	WinMove, A, , 0, 0,%w%,%h%
}

BottomLeftQuarterfWindow()
{
	SysGet, area, MonitorWorkArea
	w:=((areaRight-areaLeft)/2)
	h:=((areaBottom-areaTop)/2)

	WinRestore, A
	WinMove, A, , 0, h, w, h
}

TopRightQuarterfWindow()
{
	SysGet, area, MonitorWorkArea
	w:=((areaRight-areaLeft)/2)
	h:=((areaBottom-areaTop)/2)

	WinRestore, A
	WinMove, A, , w, 0, w, h
}

BottomRightQuarterfWindow()
{
	SysGet, area, MonitorWorkArea
	w:=((areaRight-areaLeft)/2)
	h:=((areaBottom-areaTop)/2)

	WinRestore, A
	WinMove, A, , w, h, w, h
}

MiddleWindow()
{
	SysGet, area, MonitorWorkArea
	w:=((areaRight-areaLeft)/2)
	h:=((areaBottom-areaTop)/2)

	WinRestore, A
	WinMove, A, , w/2, h/2, w, h
}

; Mapppings
^#Left::  LeftHalfWindow()  ; Default in Windows 8 is #Left
^#Right:: RightHalfWindow() ; Default in Windows 8 is #Right
^#Up::   TopHalfWindow()
^#Down:: BottomHalfWindow()
^#1:: TopLeftQuarterfWindow()
^#2:: BottomLeftQuarterfWindow()
^#3:: TopRightQuarterfWindow()
^#4:: BottomRightQuarterfWindow()
^#5:: MiddleWindow()

; }}}
; Run or activate app and kill process {{{

RoA(WinTitle, Target, WorkingDir = "%A_WorkinDir%", Size = "max") {
    IfWinExist, %WinTitle%
    {
		WinActivate, %WinTitle%
    }
	else
    {
		Run, %Target%, %WorkingDir% ,%Size%
        WinWait, %WinTitle%, , 2
        WinActivate, %WinTitle%
    }
}
^#i:: RoA("Pentadactyl", "C:\Program Files (x86)\Mozilla Firefox\firefox.exe")
^#m:: RoA("Mozilla Thunderbird", "thunderbird")
^#v:: RoA("GVIM", "gvim", "C:\OD\Users\Pedro\vimfiles")
^#s:: RoA("Skype", "C:\Program Files (x86)\Skype\Phone\Skype.exe",,"")
^#e:: RoA("Excel", "excel")
^#w:: RoA("Word", "winword")
^#t:: RoA("cmd.exe", "cmd",,"")
^#p:: RoA("Paint", "mspaint",,"")

; Kill active window process (useful to close apps like Skype)
; FIXME: Doesn't close system tray icon ;
^#k::
    WinGet, PID, PID, % "ahk_id " WinExist("A")
    Process, Close, %PID%
    Return


; }}}
; Toggle hidden files {{{

#IfWinActive ahk_class CabinetWClass
    ^h::
    RegRead, HiddenFiles_Status, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced, Hidden
    If HiddenFiles_Status = 2
        RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced, Hidden, 1
    Else
        RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced, Hidden, 2
    Send, {F5}
    Return
#IfWinActive

; }}}
; Active window screenshot {{{

^#Printscreen::
    FormatTime,CurrentTime,%A_Now%,dd-MM-yyyy_HH-mm-ss
    image_name=%A_desktop%\screenshot-%CurrentTime%.png
    Send !{Printscreen}  ; Alt-Print takes screenshot of active window in W 8.1
    RoA("Paint", "mspaint","")
    Send ^v
    Send ^s
    WinWait Save As
    WinActivate
    Send %image_name%{enter}
    Sleep 100
    WinWaitClose Save As
    Send !{F4}
    Return

; }}}
; Miscellaneous {{{

; Close applications Unix/Mac style
^q:: Send !{F4}

; Show recycle bin
#b:: Run ::{645ff040-5081-101b-9f08-00aa002f954e}
; Empty recycle bin
^#b::
    Msgbox, 4,, Do you want to empty the recycle bin?
    IfMsgBox Yes
    {
        FileRecycleEmpty
        ; MsgBox, The recycle bin has been emptied.
    }
    Return

; Shutdown and reboot (using Win+shift combination) (note: we can do this in two
; steps with Alt-F4 and Ctrl-q)
#+p:: Shutdown, 8
#+r:: Shutdown, 2

; }}}
