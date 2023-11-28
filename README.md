# SelectFile
List the files in a specified folder and return the path of the file chosen by the user.

## Example
Show all the files with `.ahk` extension in the script folder, and return the one chosen by the user.
```
selectedFile := SelectFile(A_ScriptDir, "ahk")
MsgBox(selectedFile)
```
