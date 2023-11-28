/**
 * List the files in a specified folder and return the path of the file chosen by the user.
 * @param {string} Folder Folder Path.
 * @param {string} Ext File Type. (e.g. jpg|png|gif)
 * @param {number} timeout The fuction will return 0 if timeout.
 * @returns {string} The path of the file that the user selected, or an empty string if the user did not select any file.
 */
SelectFile(Folder, Ext := "", timeout?)
{
    result := ""
    MyGui  := Gui("+AlwaysOnTop +Resize -MaximizeBox -MinimizeBox +OwnDialogs", "Select File")
    MyGui.SetFont(, "Segoe UI")
    MyGui.OnEvent("Size", Gui_Size)
    MyGui.OnEvent("Close",  (*) => (result := "", MyGui.Destroy()))
    MyGui.OnEvent("Escape", (*) => (result := "", MyGui.Destroy()))

    SwitchViewBtn := MyGui.Add("Button", , "Switch View")

    LV := MyGui.Add("ListView", "xm r10 w400 LV0x10000 Count69", ["Name", "In Folder", "Size (KB)", "Type"])
    LV.ModifyCol(3, "Integer")
    LV.SetImageList(ImageListID1 := IL_Create(10))
    LV.SetImageList(ImageListID2 := IL_Create(10, 10, true))
    LV.OnEvent("DoubleClick", GetPath.Bind(, , 1))
    LV.OnEvent("Click", GetPath)
    LV.OnEvent("ContextMenu", ShowContextMenu)

    SelectBtn := MyGui.Add("Button", "x300 w50", "Select")
    CancelBtn := MyGui.Add("Button", "w50 yp", "Cancel")
    SwitchViewBtn.OnEvent("Click", SwitchView)
    SelectBtn.OnEvent("Click", (*) => MyGui.Destroy())
    CancelBtn.OnEvent("Click", (*) => (result := "", MyGui.Destroy()))

    ContextMenu := Menu()
    ContextMenu.Add("Open", ContextOpenOrProperties)
    ContextMenu.Add("Properties", ContextOpenOrProperties)
    ContextMenu.Add("Clear from ListView", ContextClearRows)
    ContextMenu.Default := "Open"

    LoadFolder()
    MyGui.Show("Hide AutoSize")
    MyGui.GetClientPos(&MyGuiX, &MyGuiY, &MyGuiW, &MyGuiH)
    for ctrl in [SelectBtn, CancelBtn]
    {
        ctrl.GetPos(&X, &Y, &Width, &Height)
        ctrl.Xa := MyGuiW - X, ctrl.Ya := MyGuiH - Y
    }
    MyGui.Show()

    if !WinWaitClose(MyGui,, timeout?) {
        MyGui.Destroy()
        return 0
    }

    return result

    GetPath(GuiCtrl, row, dbclick := 0)
    {
        if !row
            return (result := "")

        result := format("{1}\{2}", LV.GetText(row, 2), LV.GetText(row, 1))

        if dbclick
            myGui.Destroy()
    }

    LoadFolder()
    {
        static IconMap := Map()
        if !Folder
            return

        Folder := RTrim(Folder, "\ ")

        sfi_size := A_PtrSize + 688
        sfi := Buffer(sfi_size)

        LV.Opt("-Redraw")
        Loop Files, Folder "\*.*"
        {

            if Ext && !(A_LoopFileExt ~= "iS)" Ext)
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
        FullPath := format("{1}\{2}", LV.GetText(RowNumber, 2), LV.GetText(RowNumber, 1))
        try
            Run(FullPath)
        catch
            MsgBox("Could not open " FullPath ".")
    }

    ShowContextMenu(LV, Item, IsRightClick, X, Y) => ContextMenu.Show(X, Y)

    ContextOpenOrProperties(ItemName, *)
    {
        FocusedRowNumber := LV.GetNext(0, "F")
        if not FocusedRowNumber
            return

        FullPath := format("{1}\{2}", LV.GetText(FocusedRowNumber, 2), LV.GetText(FocusedRowNumber, 1))
        
        try
        {
            if (ItemName = "Open")
                Run(FullPath)
            else
                Run("properties " FullPath)
        }
        catch
            MsgBox("Could not perform requested action on " FullPath ".")
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
