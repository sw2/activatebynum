Loop 10
{
	n := A_Index-1
	Hotkey, #%n%, Focus%n%
	Hotkey, #Numpad%n%, Focus%n%
}

return

Focus1:
FocusButton(1)
return
Focus2:
FocusButton(2)
return
Focus3:
FocusButton(3)
return
Focus4:
FocusButton(4)
return
Focus5:
FocusButton(5)
return
Focus6:
FocusButton(6)
return
Focus7:
FocusButton(7)
return
Focus8:
FocusButton(8)
return
Focus9:
FocusButton(9)
return
Focus0:
FocusButton(10)
return

Add_hWndToArray(gi, hWnd)
{
	global
	g_groupSize%gi% := g_groupSize%gi% + 1
	local wi := g_groupSize%gi%
	g_hWnd%gi%_%wi% := hWnd	
}

AddGroup(gi)
{
	global
	g_groupSize%gi% := 0
}

GroupSize(gi)
{
	global
	return g_groupSize%gi%
}

Get_hWndFromArray(gi, wi)
{
	global
	return g_hWnd%gi%_%wi%
}

Build_hWndArray(maxGroupCount)
{
	global g_groupCount
	
	WinGet,	pidTaskbar, PID, ahk_class Shell_TrayWnd
	hProc := DllCall("OpenProcess", "Uint", 0x38, "int", 0, "Uint", pidTaskbar)
	pProc := DllCall("VirtualAllocEx", "Uint", hProc, "Uint", 0, "Uint", 32, "Uint", 0x1000, "Uint", 0x4)
	idxTB := GetTaskSwBar()
	SendMessage, 0x418, 0, 0, ToolbarWindow32%idxTB%, ahk_class Shell_TrayWnd ; TB_BUTTONCOUNT
	buttonCount := ErrorLevel
	
	g_groupCount := 0
	
	Loop, %buttonCount%
	{
		SendMessage, 0x417, A_Index-1, pProc, ToolbarWindow32%idxTB%, ahk_class Shell_TrayWnd ; TB_GETBUTTON
	
		VarSetCapacity(btn, 32, 0)
		DllCall("ReadProcessMemory", "Uint", hProc, "Uint", pProc, "Uint", &btn, "Uint", 32, "Uint", 0)
		
		Statyle := NumGet(btn, 8, "Char")
		dwData := NumGet(btn, 12)
		If Not dwData
			dwData := NumGet(btn, 16, "int64")
			
		DllCall("ReadProcessMemory", "Uint", hProc, "Uint", dwData, "int64P", hWnd:=0, "Uint", NumGet(btn,12) ? 4:8, "Uint", 0)
		
		If Not hWnd ; group button, indicates the start of a group
		{
			If g_groupCount >= %maxGroupCount%
				Break
				
			hidden := Statyle & 0x08 ; TBSTATE_HIDDEN
			If hidden
				grpCollapsed := false
			Else
			{
				g_groupCount := g_groupCount + 1
				AddGroup(g_groupCount)
				grpCollapsed := true
			}
		}
		else ; actual window button
		{
			If grpCollapsed
			{
				Add_hWndToArray(g_groupCount, hWnd)
			}
			Else
			{
				g_groupCount := g_groupCount + 1
				AddGroup(g_groupCount)
				Add_hWndToArray(g_groupCount, hWnd)
			}
		}
	}

	DllCall("VirtualFreeEx", "Uint", hProc, "Uint", pProc, "Uint", 0, "Uint", 0x8000)
	DllCall("CloseHandle", "Uint", hProc)
}

FocusButton(n)
{
	global g_groupCount
	
	; these static variables can become inaccurate if windows are created or closed
	; inbetween pressing of hotkeys, but in practice, we can safely ignore the
	; inaccuracy
	static prevGroupIndex := 0
	static prevWindowIndex := 0

	Build_hWndArray(n)

	if (g_groupCount >= n)
	{
		groupSize := GroupSize(n)
		
		if n = %prevGroupIndex%
			windowIndex := Mod(prevWindowIndex, groupSize) + 1
		else
			windowIndex := 1

		hWnd := Get_hWndFromArray(n, windowIndex)

		If groupSize > 1 ; cycle through windows in the same group
			WinActivate, ahk_id %hWnd%
		Else ; single-window group; toggles between activating (restoring) and minimizing the window
			IfWinActive, ahk_id %hWnd%
				WinMinimize, ahk_id %hWnd%
			Else
				WinActivate, ahk_id %hWnd%
			
		prevGroupIndex := n
		prevWindowIndex := windowIndex
	}
}

GetTaskSwBar()
{
	ControlGet, hParent, hWnd,, MSTaskSwWClass1 , ahk_class Shell_TrayWnd
	ControlGet, hChild , hWnd,, ToolbarWindow321, ahk_id %hParent%
	Loop
	{
		ControlGet, hWnd, hWnd,, ToolbarWindow32%A_Index%, ahk_class Shell_TrayWnd
		If Not hWnd
			Break
		Else If hWnd = %hChild%
		{
			idxTB := A_Index
			Break
		}
	}
	Return	idxTB
}
