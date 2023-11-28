/**
 * List the files in a specified folder and return the path of the file chosen by the user.
 * @param {string} Folder Folder Path. 
 * @param {string} Ext File Type. (e.g. jpg|png|gif)
 * @returns {string} The path of the file that the user selected, or an empty string if the user did not select any file.
 */
SelectFile(Folder, Ext := "")
{
	result := ""
	MyGui  := Gui("+AlwaysOnTop +Resize -MaximizeBox -MinimizeBox +OwnDialogs", "Select File")
	MyGui.SetFont(, "Segoe UI")

	SwitchViewBtn := MyGui.Add("Button", , "Switch View")

	LV := MyGui.Add("ListView", "xm r10 w400 Count69", ["Name", "In Folder", "Size (KB)", "Type"])
	LV.ModifyCol(3, "Integer")
	LV.SetImageList(ImageListID1 := IL_Create(10))
	LV.SetImageList(ImageListID2 := IL_Create(10, 10, true))
	SelectBtn := MyGui.Add("Button", "x300 w50", "Select")
	CancelBtn := MyGui.Add("Button", "w50 yp", "Cancel")

	LV.OnEvent("DoubleClick", GetPath.Bind(, , 1))
	LV.OnEvent("Click", GetPath)
	LV.OnEvent("ContextMenu", ShowContextMenu)
	SwitchViewBtn.OnEvent("Click", SwitchView)
	SelectBtn.OnEvent("Click", (*) => MyGui.Destroy())
	CancelBtn.OnEvent("Click", (*) => MyGui.Destroy())
	MyGui.OnEvent("Size", Gui_Size)

	ContextMenu := Menu()
	ContextMenu.Add("Open", ContextOpenOrProperties)
	ContextMenu.Add("Properties", ContextOpenOrProperties)
	ContextMenu.Add("Clear from ListView", ContextClearRows)
	ContextMenu.Default := "Open"

	LoadFolder(Folder, Ext)
	MyGui.Show("Hide AutoSize")
	MyGui.GetClientPos(&MyGuiX, &MyGuiY, &MyGuiW, &MyGuiH)
	for ctrl in [SelectBtn, CancelBtn]
	{
		ctrl.GetPos(&X, &Y, &Width, &Height)
		ctrl.Xa := MyGuiW - X, ctrl.Ya := MyGuiH - Y
	}
	MyGui.Show()
	WinWaitClose(MyGui)

	return result

	GetPath(GuiCtrl, row, dbclick := 0)
	{
		if !row
			return

		result := (LV.GetText(row, 2) "\" LV.GetText(row, 1))

		if dbclick
			myGui.Destroy()
	}

	LoadFolder(Folder, Ext)
	{
		static IconMap := Map()
		if !Folder
			return

		if SubStr(Folder, -1, 1) = "\"
			Folder := SubStr(Folder, 1, -1)

		sfi_size := A_PtrSize + 688
		sfi := Buffer(sfi_size)

		LV.Opt("-Redraw")
		Loop Files, Folder "\*.*"
		{
			if !Ext && !(A_LoopFileExt ~= "iS)" Ext)
				continue

			FileName := A_LoopFilePath

			if A_LoopFileExt ~= "iS)\A(EXE|ICO|ANI|CUR)\z"
			{
				ExtID := A_LoopFileExt
				IconNumber := 0
			}
			else
			{
				ExtID := 0
				Loop 7
				{
					ExtChar := SubStr(A_LoopFileExt, A_Index, 1)
					if not ExtChar
						break

					ExtID := ExtID | (Ord(ExtChar) << (8 * (A_Index - 1)))
				}
				IconNumber := IconMap.Has(ExtID) ? IconMap[ExtID] : 0
			}
			if !IconNumber
			{
				if !DllCall("Shell32\SHGetFileInfoW", "Str", FileName
					, "Uint", 0, "Ptr", sfi, "UInt", sfi_size, "UInt", 0x101)
					IconNumber := 9999999
				else
				{
					hIcon := NumGet(sfi, 0, "Ptr")
					IconNumber := DllCall("ImageList_ReplaceIcon", "Ptr", ImageListID1, "Int", -1, "Ptr", hIcon) + 1
					DllCall("ImageList_ReplaceIcon", "Ptr", ImageListID2, "Int", -1, "Ptr", hIcon)

					DllCall("DestroyIcon", "Ptr", hIcon)

					IconMap[ExtID] := IconNumber
				}
			}
            
			LV.Add("Icon" . IconNumber, A_LoopFileName, A_LoopFileDir, A_LoopFileSizeKB, A_LoopFileExt)
		}
		LV.Opt("+Redraw")
		LV.ModifyCol()
		LV.ModifyCol(3, 60)
	}

	SwitchView(*)
	{
		static IconView := false
		if not IconView
			LV.Opt("+Icon")
		else
			LV.Opt("+Report")
		IconView := not IconView
	}

	RunFile(LV, RowNumber)
	{
		FileName := LV.GetText(RowNumber, 1)
		FileDir := LV.GetText(RowNumber, 2)
		try
			Run(FileDir "\" FileName)
		catch
			MsgBox("Could not open " FileDir "\" FileName ".")
	}

	ShowContextMenu(LV, Item, IsRightClick, X, Y) => ContextMenu.Show(X, Y)

	ContextOpenOrProperties(ItemName, *)
	{
		FocusedRowNumber := LV.GetNext(0, "F")
		if not FocusedRowNumber
			return

		FileName := LV.GetText(FocusedRowNumber, 1)
		FileDir := LV.GetText(FocusedRowNumber, 2)
		try
		{
			if (ItemName = "Open")
				Run(FileDir "\" FileName)
			else
				Run("properties " FileDir "\" FileName)
		}
		catch
			MsgBox("Could not perform requested action on " FileDir "\" FileName ".")
	}

	ContextClearRows(*)
	{
		RowNumber := 0
		Loop
		{
			RowNumber := LV.GetNext(RowNumber - 1)
			if not RowNumber
				break
			LV.Delete(RowNumber)
		}
	}

	Gui_Size(thisGui, MinMax, Width, Height)
	{
		Critical("Off")
		SetControlDelay(-1)
		static B3pX

		if MinMax = -1
			return

		LV.Move(, , Width - 20, Height - 80)
		if !SelectBtn.HasOwnProp("Ya")
			return

		for ctrl in [SelectBtn, CancelBtn]
		{
			ctrl.Move(Width - ctrl.Xa, Height - ctrl.Ya)
			ctrl.Redraw()
		}
	}
}
