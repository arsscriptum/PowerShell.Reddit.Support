


$Script:W32ApiCode = @"

using System;
using System.Threading;
using System.Runtime.InteropServices;
namespace W32API
{
    public static class Mouse
    {
        [DllImport("User32.dll")]
        public static extern bool SetCursorPos(int X,int Y);
    }
}

"@

$Script:BaselineTestPart1 = "A blood black nothingness began to spin. Began to spin. A system of cells interlinked within cells interlinked within cells interlinked within one stem"

$Script:BaselineTestPart2 = @"
And dreadfully distinct against the dark a tal white fountain played
Cells - Interlinked Interlinked 
Within cells interlinked - within cells interlinked - within cells interlinked
"@

$BatchFile = "$PSScriptRoot\program.bat"
$CmdExe = "$ENV:ComSpec"



        Add-Type -AssemblyName System.Windows.Forms    
        $screens = [System.Windows.Forms.SystemInformation]::VirtualScreen    

        if(-not('W32API.Mouse' -as [Type])){
            try{
                Add-Type -TypeDefinition $Script:W32ApiCode
            }catch{}
        }

        $new_x = $($screens.Width) / 2
        $new_y = $($screens.Height) / 2

        [Windows.Forms.Cursor]::Position = "$new_x, $new_y"
        $Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates $new_x, $new_y

        try{
            Add-Type -MemberDefinition '[DllImport("user32.dll")] public static extern void mouse_event(int flags, int dx, int dy, int cButtons, int info);' -Name U32 -Namespace W;
        }catch{}
      
        $ProcessData = Start-Process  -FilePath $CmdExe -ArgumentList '/C',"$BatchFile"  -WindowStyle Maximized -passthru

        Start-Sleep 5
        #move 10% along x and 10% along y and send left mouse click
        #[W.U32]::mouse_event(0x02 -bor 0x04 -bor 0x8000 -bor 0x01, .1*65535, .1 *65535, 0, 0);
        #[W.U32]::mouse_event(6,0,0,0,0);

        $wshell = New-Object -ComObject wscript.shell;

        [System.Windows.Forms.SendKeys]::SendWait($Script:BaselineTestPart1)

        Start-Sleep 2

        [System.Windows.Forms.SendKeys]::SendWait('{ENTER}')
        Start-Sleep 2
        [System.Windows.Forms.SendKeys]::SendWait('{ENTER}')
       