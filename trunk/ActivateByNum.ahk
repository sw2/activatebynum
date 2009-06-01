Loop 10
{
	n := A_Index-1
	Hotkey, #%n%, Focus%n%
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

FocusButton(n)
{
	; these static variables can become inaccurate if windows are created or closed
	; inbetween pressing of hotkeys, but in practice, we can safely ignore the
	; inaccuracy
	static prevGrpIdx := 0
	static prevBtnIdxInGrp := 0

	WinGet,	pidTaskbar, PID, ahk_class Shell_TrayWnd
	hProc := DllCall("OpenProcess", "Uint", 0x38, "int", 0, "Uint", pidTaskbar)
	pProc := DllCall("VirtualAllocEx", "Uint", hProc, "Uint", 0, "Uint", 32, "Uint", 0x1000, "Uint", 0x4)
	idxTB := GetTaskSwBar()
	SendMessage, 0x418, 0, 0, ToolbarWindow32%idxTB%, ahk_class Shell_TrayWnd ; TB_BUTTONCOUNT
	btnCnt:= ErrorLevel
	
	if (btnCnt >= n)
	{
		grpSeen := 0
		btnSeen := 0
		btnInGrpSeen := 0
		grpCollapsed := false
		
		grpIdx0 := 0
		hWnd0 := 0
		activated := false
		
		Loop, %btnCnt%
		{
			SendMessage, 0x417, A_Index-1, pProc, ToolbarWindow32%idxTB%, ahk_class Shell_TrayWnd ; TB_GETBUTTON
		
			VarSetCapacity(btn, 32, 0)
			DllCall("ReadProcessMemory", "Uint", hProc, "Uint", pProc, "Uint", &btn, "Uint", 32, "Uint", 0)
			
			Statyle := NumGet(btn, 8, "Char")
			dwData := NumGet(btn, 12)
			If Not dwData
				dwData := NumGet(btn, 16, "int64")
				
			DllCall("ReadProcessMemory", "Uint", hProc, "Uint", dwData, "int64P", hWnd:=0, "Uint", NumGet(btn,12) ? 4:8, "Uint", 0)
			
			If Not hWnd ; group button
			{
				grpSeen := grpSeen + 1
				
				hidden := Statyle & 0x08 ; TBSTATE_HIDDEN
				If hidden
				{
					If btnSeen = %n% ; the button we're trying to find were in the previous collapsed group
						Break
					grpCollapsed := false
				}
				Else ; the group is collapsed
				{
					btnSeen := btnSeen + 1
					if btnSeen > %n%
						Break
					grpCollapsed := true
				}
			}
			Else ; actual window button
			{
				If grpCollapsed
				{
					If btnSeen = %n%
					{
						if prevGrpIdx != %grpSeen%
							prevBtnIdxInGrp := 0
					
						btnInGrpSeen := btnInGrpSeen + 1

						If btnInGrpSeen = 1
						{
							; remember them in case we need them for wrapping
							grpIdx0 := grpSeen
							hWnd0 := hWnd
						}
						
						btnIdxInGrpToMatch := prevBtnIdxInGrp + 1

						If btnInGrpSeen = %btnIdxInGrpToMatch%
						{
							WinActivate, ahk_id %hWnd%
							prevGrpIdx := grpSeen
							prevBtnIdxInGrp := btnInGrpSeen
							activated := true
							Break
						}
					}
				}
				Else
				{
					btnSeen := btnSeen + 1
					if btnSeen > %n%
						Break
				
					If btnSeen = %n%
					{
						WinActivate, ahk_id %hWnd%
						prevGrpIdx := grpSeen
						prevBtnIdxInGrp := 1
						activated := true
						Break
					}
				}
			}
		}
		
		if (grpCollapsed = true && btnSeen >= %n% && activated = false)
		{
			; this handles the k+1-th time WIN+n is pressed (consecutively) when the n-th group has only k window buttons
			; we activate the first window in this group
			WinActivate, ahk_id %hWnd0%
			prevGrpIdx := grpIdx0
			prevBtnIdxInGrp := 1
		}
	}

	DllCall("VirtualFreeEx", "Uint", hProc, "Uint", pProc, "Uint", 0, "Uint", 0x8000)
	DllCall("CloseHandle", "Uint", hProc)
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
