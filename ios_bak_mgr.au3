#AutoIt3Wrapper_UseX64=N
#AutoIt3Wrapper_UseUpx=N
#AutoIt3Wrapper_Compression=4
;#AutoIt3Wrapper_Icon=.ico
;#AutoIt3Wrapper_OutFile=.exe
#AutoIt3Wrapper_Res_Description=iOS Backup Manager
#AutoIt3Wrapper_Res_Language=1033

#include <Array.au3>
#include <File.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <StaticConstants.au3>
#include <Constants.au3>
#include <StringConstants.au3>
#include <ComboConstants.au3>
#include <GuiListView.au3>

#NoTrayIcon
Opt("TrayAutoPause",0)
AutoItSetOption("WinTitleMatchMode", 2)     ;1=start, 2=subStr, 3=exact, 4=advanced, -1 to -4=Nocase
Opt("GUIOnEventMode", 1)  ; Change to OnEvent mode

Const $script_name = 'iOS Backup Manager'

; Options
	$sleep_delay=100
	$ini_path = StringReplace(StringReplace(@ScriptFullPath, ".exe", ".ini"), ".au3", ".ini")
	$backups_path = @HomePath & '\AppData\Roaming\Apple Computer\MobileSync\Backup'
; End Options

; Init Variables
	Global $gui_closed = False
	Global $gui_hnd = -1
	Global $aBackups[1]
	Global $aBackupsName[1]
	Global $aBackupsDate[1]
	Global $aBackupsProduct[1]
	Global $aBackupsSerial[1]
	Global $aBackupsPhone[1]
	Global $aBackupsOsVersion[1]
	Global $aBackupsArchiveDate[1]
	$aBackups[0]=0
	$aBackupsName[0]=0
	$aBackupsDate[0]=0
	$aBackupsProduct[0]=0
	$aBackupsSerial[0]=0
	$aBackupsPhone[0]=0
	$aBackupsOsVersion[0]=0
	$aBackupsArchiveDate[0]=0
	Global $list_items[1]
	$list_items[0]=0
; End Init Variables

; Create a GUI
$line_height = 15
$ctrl_width = 900
$ctrl_height = 480
;$ctrl_height = 170
$ctrl_left = (@DesktopWidth - $ctrl_width) / 2
$ctrl_top = (@DesktopHeight - $ctrl_height) / 2
$gui_hnd = GUICreate($script_name, $ctrl_width, $ctrl_height, $ctrl_left, $ctrl_top, BitOr($WS_CAPTION, $WS_POPUP, $WS_SYSMENU))
GUISetOnEvent($GUI_EVENT_CLOSE, "EventHandler", $gui_hnd)
GUISetState(@SW_SHOW, $gui_hnd)

$listview = GUICtrlCreateListView("Archived On|Device|Date|Product|Serial|iOS|Phone", 10, 10, 880, 410)

$btn_explore = GUICtrlCreateButton("Explore", 10, 450, 80, 20)
GUICtrlSetOnEvent($btn_explore, "EventHandler")

$btn_archive = GUICtrlCreateButton("Archive", 100, 450, 80, 20)
GUICtrlSetOnEvent($btn_archive, "EventHandler")

$btn_undo = GUICtrlCreateButton("Undo Archive", 190, 450, 80, 20)
GUICtrlSetOnEvent($btn_undo, "EventHandler")

$btn_rename = GUICtrlCreateButton("Rename", 280, 450, 80, 20)
GUICtrlSetOnEvent($btn_rename, "EventHandler")

#cs
$btn_delete = GUICtrlCreateButton("Delete", 250, 350, 50, 20)
GUICtrlSetOnEvent($btn_delete, "EventHandler")

$btn_advanced = GUICtrlCreateButton("Advanced", 340, 350, 60, 20)
GUICtrlSetOnEvent($btn_advanced, "EventHandler")

$btn_add = GUICtrlCreateButton("Add", 430, 350, 50, 20)
GUICtrlSetOnEvent($btn_add, "EventHandler")
#ce

get_backups()

While True
	If $gui_closed Then
		Exit
	EndIf

	Sleep($sleep_delay)

WEnd

Func EventHandler()
	Switch @GUI_CtrlId
		Case $GUI_EVENT_CLOSE
			$gui_closed = True
			GUISetState(@SW_HIDE, $gui_hnd)
		Case $btn_explore
			ShowFolder()
		Case $btn_archive
			ArchiveBackup()
		Case $btn_undo
			UndoArchiveBackup()
		Case $btn_rename
			RenameBackup()
	EndSwitch
EndFunc

Func get_backups()
	; Clear Arrays
	clear_array($aBackups)
	clear_array($aBackupsName)
	clear_array($aBackupsDate)
	clear_array($aBackupsProduct)
	clear_array($aBackupsSerial)
	clear_array($aBackupsPhone)
	clear_array($aBackupsOsVersion)
	clear_array($aBackupsArchiveDate)


	$aBackupFolders = _FileListToArray($backups_path, '*', $FLTA_FOLDERS, False)

	For $x = 1 To $aBackupFolders[0]
		get_backup_info($aBackupFolders[$x])
	Next

	update_listview()
EndFunc

Func get_backup_info($folder)
	If FileExists($backups_path & '\' & $folder & '\Info.plist') Then
		; Add to folder array
		_ArrayAdd($aBackups, $folder)
		$aBackups[0] += 1

		; Create array items with blank value (in case of error)
		_ArrayAdd($aBackupsName, '')
		_ArrayAdd($aBackupsDate, '')
		_ArrayAdd($aBackupsProduct, '')
		_ArrayAdd($aBackupsSerial, '')
		_ArrayAdd($aBackupsPhone, '')
		_ArrayAdd($aBackupsOsVersion, '')
		_ArrayAdd($aBackupsArchiveDate, '')
		$aBackupsName[0] += 1
		$aBackupsDate[0] += 1
		$aBackupsProduct[0] += 1
		$aBackupsSerial[0] += 1
		$aBackupsPhone[0] += 1
		$aBackupsOsVersion[0] += 1
		$aBackupsArchiveDate[0] += 1

		; Read file into string variable
		$sInfoData = FileRead($backups_path & '\' & $folder & '\Info.plist')

		; Get values from file
		$aBackupsName[$aBackupsName[0]] = get_info_item($sInfoData, 'Display Name', 'string')
		If $aBackupsName[$aBackupsName[0]] = '' Then
			$aBackupsName[$aBackupsName[0]] = 'Unknown'
		EndIf
		$aBackupsDate[$aBackupsDate[0]] = get_info_item($sInfoData, 'Last Backup Date', 'date')
		$aBackupsProduct[$aBackupsProduct[0]] = get_info_item($sInfoData, 'Product Name', 'string')
		$aBackupsSerial[$aBackupsSerial[0]] = get_info_item($sInfoData, 'Serial Number', 'string')
		$aBackupsPhone[$aBackupsPhone[0]] = StringRegExpReplace(get_info_item($sInfoData, 'Phone Number', 'string'), '^\+?1 \(', '(')
		$aBackupsOsVersion[$aBackupsOsVersion[0]] = get_info_item($sInfoData, 'Product Version', 'string')

		$sRegExp = '.*-(\d{4})(\d{2})(\d{2})-(\d{2})(\d{2})(\d{2})'
		$aMatches = StringRegExp($folder, $sRegExp, $STR_REGEXPARRAYMATCH)

		If IsArray($aMatches) Then
			If UBound($aMatches) > 4 Then
				$aBackupsArchiveDate[$aBackupsArchiveDate[0]] =  $aMatches[1] & '/' & $aMatches[2] & '/' & $aMatches[0] & ' ' & $aMatches[3] & ':' & $aMatches[4]
			EndIf
		EndIf
	EndIf
EndFunc

Func get_info_item($data, $key, $type)
	$sRegExp = '<key>' & $key & '</key>\s*<' & $type & '>(.*)</' & $type & '>'
	$aMatches = StringRegExp($data, $sRegExp, $STR_REGEXPARRAYMATCH)

	If IsArray($aMatches) Then
		If UBound($aMatches) > 0 Then
			Return $aMatches[0]
		EndIf
	EndIf

	Return ''
EndFunc



Func ShowFolder()
	$sel_idx = _GUICtrlListView_GetSelectionMark($listview)
	$backup_idx = $sel_idx + 1

	$folder = $backups_path & '\' & $aBackups[$backup_idx]

	ShellExecute($folder)
EndFunc


Func ArchiveBackup()
	$sel_idx = _GUICtrlListView_GetSelectionMark($listview)
	$backup_idx = $sel_idx + 1

	If $aBackupsArchiveDate[$backup_idx] <> '' Then
		$folder = $backups_path & '\' & $aBackups[$backup_idx]

		$new_folder = $folder
		$new_folder &= '-' & stringformat("%04d%02d%02d",@YEAR, @MON, @MDAY)
		$new_folder &= '-' & stringformat("%02d%02d%02d",@HOUR, @MIN, @SEC)

		DirMove($folder, $new_folder)
		get_backups()
	Else
		MsgBox($MB_OK + $MB_ICONWARNING, $script_name, 'The selected backup is already archived!')
	EndIf
EndFunc

Func RenameBackup()
	$sel_idx = _GUICtrlListView_GetSelectionMark($listview)
	$backup_idx = $sel_idx + 1

	If $aBackupsArchiveDate[$backup_idx] <> '' Then
		$folder = $backups_path & '\' & $aBackups[$backup_idx]


		get_backups()
	Else
		MsgBox($MB_OK + $MB_ICONWARNING, $script_name, 'The selected backup is not archived!')
	EndIf
EndFunc

Func UndoArchiveBackup()
	$sel_idx = _GUICtrlListView_GetSelectionMark($listview)
	$backup_idx = $sel_idx + 1

	If $aBackupsArchiveDate[$backup_idx] <> '' Then
		$folder = $backups_path & '\' & $aBackups[$backup_idx]

		$new_folder = StringRegExpReplace($folder, '(.*)-\d{8}-\d{6}', '$1')

		If FileExists($new_folder) Then
			MsgBox($MB_OK + $MB_ICONWARNING, $script_name, 'Unable to undo archive!' & @CRLF & @CRLF & 'Another backup was created after the archived backup!')
		Else
			DirMove($folder, $new_folder)
			get_backups()
		EndIf
	Else
		MsgBox($MB_OK + $MB_ICONWARNING, $script_name, 'The selected backup is not archived!')
	EndIf
EndFunc

Func update_listview()
	; Clear Old Values
	_GUICtrlListView_DeleteAllItems($listview)
	While $list_items[0] > 0
		_ArrayDelete($list_items, $list_items[0])
		$list_items[0] -= 1
	WEnd

	; Repopulate List View
	For $x = 1 To $aBackups[0]
		$sListItem = $aBackupsArchiveDate[$x]
		$sListItem &= '|' & $aBackupsName[$x]
		$sListItem &= '|' & $aBackupsDate[$x]
		$sListItem &= '|' & $aBackupsProduct[$x]
		$sListItem &= '|' & $aBackupsSerial[$x]
		$sListItem &= '|' & $aBackupsOsVersion[$x]
		$sListItem &= '|' & $aBackupsPhone[$x]
		_ArrayAdd($list_items, GUICtrlCreateListViewItem($sListItem, $listview))
		$list_items[0] += 1
	Next
	autosize_columns($listview)
EndFunc

Func clear_array(ByRef $in_array)
	While $in_array[0] > 0
		_ArrayDelete($in_array, $in_array[0])
		$in_array[0] -= 1
	WEnd
EndFunc

Func autosize_columns($in_listview)
	$padding = 20
	$cnt = _GUICtrlListView_GetColumnCount

	For $iCol = 0 to $cnt - 1
		_GUICtrlListView_SetColumnWidth($in_listview, $iCol, $LVSCW_AUTOSIZE)
		$w1 = _GUICtrlListView_GetColumnWidth($in_listview, $iCol)
		_GUICtrlListView_SetColumnWidth($in_listview, $iCol, $LVSCW_AUTOSIZE_USEHEADER)
		$w2 = _GUICtrlListView_GetColumnWidth($in_listview, $iCol)
		If $w2 > $w1 Then
			_GUICtrlListView_SetColumnWidth($in_listview, $iCol, ($w2 + $padding))
		Else
			_GUICtrlListView_SetColumnWidth($in_listview, $iCol, ($w1 + $padding))
		EndIf
	Next
EndFunc

