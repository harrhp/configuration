$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function LightsOut {
  rundll32.exe user32.dll, LockWorkStation;
  (Add-Type '[DllImport("user32.dll")]public static extern int PostMessage(int hWnd, int hMsg, int wParam, int lParam);' -Name a -PassThru)::PostMessage(-1, 0x0112, 0xF170, 2);
}
