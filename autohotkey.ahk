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
; Multiple monitors handling {{{

GetCurrentMonitor()
{
  SysGet, numberOfMonitors, MonitorCount
  WinGetPos, winX, winY, winWidth, winHeight, A
  winMidX := winX + winWidth / 2
  winMidY := winY + winHeight / 2
  Loop %numberOfMonitors%
  {
    SysGet, monArea, Monitor, %A_Index%
    if (winMidX > monAreaLeft && winMidX < monAreaRight && winMidY < monAreaBottom && winMidY > monAreaTop)
      Return A_Index
  }
}

; }}}
; Window handling {{{

LeftHalfWindow()
{
    currMon := GetCurrentMonitor()
    ; Get the resolution of the current monitor (excluding taskbar)
	SysGet, area, MonitorWorkArea, %currMon%
	w:=((areaRight-areaLeft)/2)
	h:=(areaBottom-areaTop)
    ; Set the upper-left pixel of the first screen
    x := 0
    y := 0
    if (currMon = 2) {
        ; If we are in the second monitor (and assuming this monitor is to the
        ; left) we need to shift the upper-left pixel of the screen by the
        ; second monitor screen resolution
        x := -(areaRight - areaLeft)
        ; Now get the primary monitor height resolution (including taskbar)
        SysGet, mon1_area, Monitor, 1
        ; Move the height up by the difference in height resolution between the
        ; biggest monitor (second) and the smaller one (first)
        y:= -((areaBottom - areaTop) - (mon1_areaBottom - mon1_areaTop))
    }

    WinRestore, A
    WinMove, A, , x, y,%w%,%h%
}

RightHalfWindow()
{
    currMon := GetCurrentMonitor()
	SysGet, area, MonitorWorkArea, %currMon%
	w:=((areaRight-areaLeft)/2)
	h:=(areaBottom-areaTop)
    x := w
    y := 0
    if (currMon = 2) {
        x := w -(areaRight - areaLeft)
        SysGet, mon1_area, Monitor, 1
        y:= -((areaBottom - areaTop) - (mon1_areaBottom - mon1_areaTop))
    }

	WinRestore, A
	WinMove, A, , x, y, w, h
}

TopHalfWindow()
{
    currMon := GetCurrentMonitor()
	SysGet, area, MonitorWorkArea, %currMon%
	w:=(areaRight-areaLeft)
	h:=((areaBottom-areaTop)/2)
    x := 0
    y := 0
    if (currMon = 2) {
        x := -(areaRight - areaLeft)
        SysGet, mon1_area, Monitor, 1
        y:= -((areaBottom - areaTop) - (mon1_areaBottom - mon1_areaTop))
    }

	WinRestore, A
	WinMove, A, , x, y, w, h
}

BottomHalfWindow()
{
    currMon := GetCurrentMonitor()
	SysGet, area, MonitorWorkArea, %currMon%
	w:=(areaRight-areaLeft)
	h:=((areaBottom-areaTop)/2)
    x := 0
    y := h
    if (currMon = 2) {
        x := -(areaRight - areaLeft)
        SysGet, mon1_area, Monitor, 1
        y:= h - ((areaBottom - areaTop) - (mon1_areaBottom - mon1_areaTop))
    }

	WinRestore, A
	WinMove, A, , x, y, w, h
}

TopLeftQuarterfWindow()
{
    currMon := GetCurrentMonitor()
	SysGet, area, MonitorWorkArea, %currMon%
	w:=((areaRight-areaLeft)/2)
	h:=((areaBottom-areaTop)/2)
    x := 0
    y := 0
    if (currMon = 2) {
        x := -(areaRight - areaLeft)
        SysGet, mon1_area, Monitor, 1
        y:= -((areaBottom - areaTop) - (mon1_areaBottom - mon1_areaTop))
    }

	WinRestore, A
	WinMove, A, , x, y,%w%,%h%
}

BottomLeftQuarterfWindow()
{
    currMon := GetCurrentMonitor()
	SysGet, area, MonitorWorkArea, %currMon%
	w:=((areaRight-areaLeft)/2)
	h:=((areaBottom-areaTop)/2)
    x := 0
    y := h
    if (currMon = 2) {
        x := -(areaRight - areaLeft)
        SysGet, mon1_area, Monitor, 1
        y:= h - ((areaBottom - areaTop) - (mon1_areaBottom - mon1_areaTop))
    }

	WinRestore, A
	WinMove, A, , x, y, w, h
}

TopRightQuarterfWindow()
{
    currMon := GetCurrentMonitor()
	SysGet, area, MonitorWorkArea, %currMon%
	w:=((areaRight-areaLeft)/2)
	h:=((areaBottom-areaTop)/2)
    x := w
    y := 0
    if (currMon = 2) {
        x := w -(areaRight - areaLeft)
        SysGet, mon1_area, Monitor, 1
        y:= -((areaBottom - areaTop) - (mon1_areaBottom - mon1_areaTop))
    }

	WinRestore, A
	WinMove, A, , x, y, w, h
}

BottomRightQuarterfWindow()
{
    currMon := GetCurrentMonitor()
	SysGet, area, MonitorWorkArea, %currMon%
	w:=((areaRight-areaLeft)/2)
	h:=((areaBottom-areaTop)/2)
    x := w
    y := h
    if (currMon = 2) {
        x := w -(areaRight - areaLeft)
        SysGet, mon1_area, Monitor, 1
        y:= h - ((areaBottom - areaTop) - (mon1_areaBottom - mon1_areaTop))
    }

	WinRestore, A
	WinMove, A, , x, y, w, h
}

MiddleWindow()
{
    currMon := GetCurrentMonitor()
	SysGet, area, MonitorWorkArea, %currMon%
	w:=((areaRight-areaLeft)/2)
	h:=((areaBottom-areaTop)/2)
    x := w / 2
    y := h /2
    if (currMon = 2) {
        x := (-(areaRight - areaLeft) - w) / 2
        SysGet, mon1_area, Monitor, 1
        y := (-((areaBottom - areaTop) - (mon1_areaBottom - mon1_areaTop)) / 2.5)
    }

	WinRestore, A
	WinMove, A, , x, y, w, h
}

; Mapppings
#Left::  LeftHalfWindow()  ; Default in Windows 10 is #Left
#Right:: RightHalfWindow() ; Default in Windows 10 is #Right
^#Up::   TopHalfWindow()
^#Down:: BottomHalfWindow()
^#1:: TopLeftQuarterfWindow()
^#2:: BottomLeftQuarterfWindow()
^#3:: TopRightQuarterfWindow()
^#4:: BottomRightQuarterfWindow()
^#5:: MiddleWindow()

; Move windows left and right between monitors
; FIXME: Respect window width!
^#Left:: Send #+{Left}
^#Right:: Send #+{Right}

; Expose/Task View (show thumbnails of open windows)
^#j:: Send #{Tab}

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
^#x:: RoA("Excel", "excel")
^#w:: RoA("Word", "winword")
^#l:: RoA("Slack", "C:\Users\Pedro\AppData\Local\slack\Update.exe --processStart slack.exe")
^#c:: RoA("cmd.exe", "cmd",,"")
; ^#c:: RoA("cmd", "C:\Program Files\ConEmu\ConEmu64.exe")
^#d:: RoA("Downloads", "C:\Users\Pedro\Downloads",,"")
^#f:: RoA("This PC", "explorer")
^#p:: RoA("SumatraPDF", "SumatraPDF")
^#m:: RoA("Spotify Premium", "C:\Users\Pedro\AppData\Roaming\Spotify\Spotify.exe",,"")

; Kill active window process (useful to close apps like Skype or Vuze)
; FIXME: Doesn't close system tray icon ;
^#k::
    WinGet, PID, PID, % "ahk_id " WinExist("A")
    Process, Close, %PID%
    Return

; }}}
; Vim specific {{{

; Run or activate gvim
^#v:: RoA("GVIM", "gvim", "C:\OD\OneDrive\vimfiles")

; Restart gvim and load previous session
^#r::
    Send :wall!{Enter}
    Send {,}kv
    Sleep 150
    RoA("GVIM", "gvim", "C:\OD\OneDrive\vimfiles")
    Sleep 150
    Send {,}ps
    Return

; Open Gvim sourcing the minimal vimrc
; ^#m:: Run, gvim -u C:/OD/OneDrive/vimfiles/vimrc_min, C:/OD/OneDrive/vimfiles, max

; }}}
; Spotify and Volume {{{

; Spotify
#+p::Media_Play_Pause
#+j::Media_Next
#+k::Media_Prev
#+t::
{
    DetectHiddenWindows, On
    WinGetTitle, now_playing, ahk_class SpotifyMainWindow
    StringTrimLeft, playing, now_playing, 0
    Msgbox,,Spotify Current Track, %playing%, 1.5
    DetectHiddenWindows, Off
    Return
}

; Volume control
#+=::
{
    SoundGet, mute_state, , mute
    If mute_state=On
        SoundSet, +1, , mute
    SoundSet +5
    SoundGet, master_volume
    vol:=Floor(master_volume)
    MsgBox,, Volume level, Volume level: %vol%`%., 0.7
    Return
}
#+-::
{
    SoundSet -5
    SoundGet, master_volume
    vol:=Floor(master_volume)
    MsgBox,, Volume level, Volume level: %vol%`%., 0.7
    Return
}
#+m:: SoundSet, +1, , mute
#+v::
{
    SoundGet, master_volume
    vol:=Floor(master_volume)
    MsgBox,, Volume level, Volume level: %vol%`%., 1.5
    Return
}

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
#+5::
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
; Miscellaneous {{{

; Close applications and window Mac style
#q:: Send !{F4}
#w:: Send ^w

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

; Shutdown and reboot (using Win+shift combination) (note: we can do this in two
; steps with Alt-F4 and Ctrl-q)
#+s::
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
