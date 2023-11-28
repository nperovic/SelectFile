# SelectFile
List the files in a specified folder and return the path of the file chosen by the user. 

This is not like the system's default file selection dialog box. Users **"cannot"** navigate to other folders in this dialog box.

## Example
Show all the files with `.ahk` extension in the script folder, and return the one chosen by the user.
```
selectedFile := SelectFile(A_ScriptDir, "ahk")
MsgBox(selectedFile)
```
