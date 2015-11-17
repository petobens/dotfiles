;-==============================================================================
;          File: autohotkey.ahk
;        Author: Pedro Ferrari
;       Created: 09 Apr 2014
; Last Modified: 17 Nov 2015
;   Description: Autohotkey configuration file
;===============================================================================
; Preamble {{{

#NoEnv
#NoTrayIcon
SendMode Input
SetTitleMatchMode, 2   ; Window title can contain WinTitle anywhere

; Reload (a)utohotkey script
^#a::
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
; ; FIXME: If I use windows key (#) instead of shift(+) it doesn't work
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
^#u:: RoA("Vuze", "C:\Program Files\Vuze\Azureus.exe")
^#t:: RoA("Mozilla Thunderbird", "thunderbird")
^#s:: RoA("Skype", "C:\Program Files (x86)\Skype\Phone\Skype.exe",,"")
^#g:: RoA("GifCam", "C:\OD\OneDrive\apps\GifCam.exe",,"")
^#e:: RoA("Excel", "excel")
^#w:: RoA("Word", "winword")
^#c:: RoA("cmd.exe", "cmd",,"")
^#d:: RoA("Downloads", "C:\Users\Pedro\Downloads",,"")
^#p:: RoA("SumatraPDF", "SumatraPDF")

; Kill active window process (useful to close apps like Skype or Vuze)
; FIXME: Doesn't close system tray icon ;
^#k::
    WinGet, PID, PID, % "ahk_id " WinExist("A")
    Process, Close, %PID%
    Return

; }}}
; Vim specific {{{

; Run or activate gvim
^#v:: RoA("GVIM", "gvim", "C:\OD\OneDrive\Users\Pedro\vimfiles")

; Restart gvim and load previous session
^#r::
    Send :wall!{Enter}
    Send KK
    Sleep 150
    RoA("GVIM", "gvim", "C:\OD\OneDrive\Users\Pedro\vimfiles")
    Sleep 150
    Send {,}ps
    Return

; Open Gvim sourcing the minimal vimrc
^#m:: Run, gvim -u C:/OD/OneDrive/Users/Pedro/vimfiles/vimrc_min, C:/OD/OneDrive/Users/Pedro/vimfiles, max

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

; Note that for this to work we need first to resize the default paint image
; size to something small (for instance 100x100 pixels)
^#Printscreen::
    FormatTime,CurrentTime,%A_Now%,dd-MM-yyyy_HH-mm-ss
    image_name=%A_desktop%\screenshot-%CurrentTime%.png
    ; Alt-Print takes screenshot of active window in W >= 8.1
    Send !{Printscreen}
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
; Wireless/internet connections {{{

; Show Wireless IP4 properties
#w::
    Run ::{7007acc7-3202-11d1-aad2-00805fc1270e},, max
    WinWaitActive, Network Connections
    MiddleWindow()
    Send {Space}w{AppsKey}
    Sleep 250
    Send {Down 9}{Enter}
    WinWaitActive, Wi-Fi Fijo Properties
    Sleep 300
    Send {Down 9}
    ControlClick, P&roperties,,,,3
    Return

; Automatically set Network settings (requires running autohotkey as admin)
; FIXME: If run as admin startup script is not executed
^#n::
    {
    SetTimer, ChangeButtonNames, 50
    Msgbox, 4, Static or Automatic IP Address, Do you want to use a static IP address?
    IfMsgBox Yes
    {
    Run, %comspec% /c netsh interface ip set address "Wi-Fi Fijo" source=static address=192.168.50.130 mask=255.255.255.0 gateway=192.168.50.1
    Run, %comspec% /c netsh interface ip set dnsservers "Wi-Fi Fijo" source=static address=192.168.50.3 primary
    }
	else
    {
    Run, %comspec% /c netsh interface ip set address "Wi-Fi Fijo" source=dhcp
    Run, %comspec% /c netsh interface ip set dnsservers "Wi-Fi Fijo" source=dhcp
    }
    }
    Return

; Helper function to change button names
ChangeButtonNames:
    IfWinNotExist, Static or Automatic IP Address
        Return
    SetTimer, ChangeButtonNames, off
    WinActivate
    ControlSetText, Button1, &Static (AF)
    ControlSetText, Button2, &Automatic
    Return

; }}}
; Miscellaneous {{{

; Close applications Unix/Mac style
^q:: Send !{F4}

; Make Capslock a Tab key (but allow to retain Capslock with Shift+Capslock)
+Capslock::Capslock
Capslock::Tab

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

; Toggle Synergy scroll lock
^#l::
    Send #+l
    MsgBox, Cursor should  now be locked (unlocked) to (from) this screen.`nIn case this didn't work type 'WinKey+Shift+l'.
    Return

; Shutdown and reboot (using Win+shift combination) (note: we can do this in two
; steps with Alt-F4 and Ctrl-q)
#+p::
    Msgbox, 4, Shutdown option, Do you want to shutdown your computer?
    IfMsgBox Yes
    {
        Shutdown, 8
    }
    Return

#+r::
    Msgbox, 4, Reboot option, Do you want to restart your computer?
    IfMsgBox Yes
    {
        Shutdown, 2
    }
    Return

; }}}
