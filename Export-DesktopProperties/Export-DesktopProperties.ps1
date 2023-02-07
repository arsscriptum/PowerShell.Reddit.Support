
<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>


[string]$CsSource = @"
    using System;
    using System.Runtime.InteropServices;
    public class WindowPropertiesExporter {
        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool GetWindowRect(IntPtr hWnd, out WinRect lpRect);

        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);
        [DllImport("user32.dll", SetLastError = true)]
        public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

        [DllImport("user32.dll", SetLastError = true)]
        public static extern IntPtr FindWindow(string lpClassName, IntPtr lpWindowName);

        [DllImport("user32.dll", SetLastError = true)]
        public static extern IntPtr FindWindow(IntPtr lpClassName, string lpWindowName);
        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool SetForegroundWindow(IntPtr hWnd);

        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    }
    public struct WinCoords{
        public int X;      
        public int Y;       
    }
    public struct WinRect{
        public int Left;        // x position of upper-left corner
        public int Top;         // y position of upper-left corner
        public int Right;       // x position of lower-right corner
        public int Bottom;      // y position of lower-right corner
    }
"@

class WindowCoords{
    [int]$X 
    [int]$Y
    WindowCoords(){
        $this.X = 0;
        $this.Y = 0;
    }
    WindowCoords([int]$x, [int]$y){
        $this.X = $x;
        $this.Y = $y;
    }
    [void]Dump(){
        Write-Host "X $($this.X), Y $($this.Y)" -n
    }
    [string]GetDumpStr(){
        [string]$res = "X $($this.X), Y $($this.Y)"
        return $res
    }
}
class WindowProperties{
    [WindowCoords]$TopLeft 
    [WindowCoords]$BottomRight
    [int]$Height
    [int]$Width
    [int]$Left
    [int]$Top
    [int]$Right
    [int]$Bottom
    [string]$Name
    WindowProperties(){
        $this.TopLeft = [WindowCoords]::new();
        $this.BottomRight = [WindowCoords]::new();
        $this.Height = 0;
        $this.Width = 0;
        $this.Left = 0;
        $this.Top = 0;
        $this.Right = 0;
        $this.Bottom = 0;
        $this.Name = ''
    }
    WindowProperties([string]$name, [WindowCoords]$topleft, [WindowCoords]$bottomright, [int]$height,[int]$width, [int]$left, [int]$top, [int]$right, [int]$bottom){
        $this.TopLeft = [WindowCoords]::new($topleft.X, $topleft.Y);
        $this.BottomRight = [WindowCoords]::new($bottomright.X, $bottomright.Y);
        $this.Height = $height
        $this.Width = $width
        $this.Left = $left
        $this.Top = $top
        $this.Right = $right
        $this.Bottom = $bottom
        $this.Name = $name
    }
    [void]Dump(){
        Write-Host "TopLeft $($this.TopLeft.Dump()), BottomRight $($this.BottomRight.Dump()), Height $($this.Height), Width $($this.Width), Left $($this.Left), Top $($this.Top), Right $($this.Right), Bottom $($this.Bottom), name $($this.Name)"
    }
}


function Export-DesktopProperties{
    [CmdletBinding(SupportsShouldProcess)]
    Param
    (
        [Parameter(Mandatory = $false)]
        [string]$Path="$PSScriptRoot\DesktopProperties.xml"
    )
  
    try{
    if (!("WindowPropertiesExporter" -as [type])) {
            Write-Verbose "Registering WindowPropertiesExporter... " 
            Add-Type -TypeDefinition "$CsSource"
        }else{
            Write-Verbose "WindowPropertiesExporter already registered " 
        }

        $PropertyList = [System.Collections.ArrayList]::new()
        Get-WindowProcesses | ForEach-Object {
            $ps = $_
            [string]$psname = $ps.ProcessName
            if ($ps.MainWindowHandle -ne 0) {
        
                $Rectangle = New-Object WinRect
                [WindowPropertiesExporter]::GetWindowRect($ps.MainWindowHandle,[ref]$Rectangle) | Out-Null
               
                # If the Window position is invalid, it probably means it is minimized, so to get the correct coordinates
                # we will set the focus on the app temporarly and call GetWindowRect again.
                If ($Rectangle.Top    -lt 0 -AND 
                    $Rectangle.Bottom -lt 0 -AND
                    $Rectangle.Left   -lt 0 -AND
                    $Rectangle.Right  -lt 0) {
     
                    [void] [WindowPropertiesExporter]::SetForegroundWindow($ps.MainWindowHandle)

                    # SW_RESTORE (9)
                    # Activates and displays the window. If the window is minimized or maximized, 
                    # the system restores it to its original size and position. An application should specify this flag when restoring a minimized window.
                    [void] [WindowPropertiesExporter]::ShowWindow($ps.MainWindowHandle, 9)

                    [WindowPropertiesExporter]::GetWindowRect($ps.MainWindowHandle,[ref]$Rectangle) | Out-Null
                    Write-Warning "$($_.ProcessName) SetForegroundWindow"
                }
                [int]$Height      = $Rectangle.Bottom - $Rectangle.Top
                [int]$Width       = $Rectangle.Right  - $Rectangle.Left
              
                [WindowCoords]$TopLeft     = [WindowCoords]::new($Rectangle.Left , $Rectangle.Top)
                [WindowCoords]$BottomRight = [WindowCoords]::new($Rectangle.Right , $Rectangle.Bottom)

                [WindowProperties]$props = [WindowProperties]::new($ps.ProcessName, 
                    $TopLeft, 
                    $BottomRight, 
                    $Height, 
                    $Width, 
                    $Rectangle.Left, 
                    $Rectangle.Top, 
                    $Rectangle.Right, 
                    $Rectangle.Bottom)
                [void]$PropertyList.Add($props)
            
            }
        }

        Export-CliXml -Path $Path -InputObject $PropertyList
        Write-Host "All windows properties saved to $Path" 
    }catch{
        Write-Error "$_"
    }
}

function Import-DesktopProperties{
    [CmdletBinding(SupportsShouldProcess)]
    Param
    (
        [Parameter(Mandatory = $false)]
        [string]$Path="$PSScriptRoot\DesktopProperties.xml"
    )

    try{
        if(-not (Test-Path $Path -PathType Leaf)){ throw "No such file $Path" }
      

        if (!("WindowPropertiesExporter" -as [type])) {
            Write-Verbose "Registering WindowPropertiesExporter... " 
            Add-Type -TypeDefinition "$CsSource"
        }else{
            Write-Verbose "WindowPropertiesExporter already registered " 
        }

        Write-Host "Import all windows properties"
        $PropertyList = Import-CliXml -Path $Path 

        ForEach($prop in $PropertyList){
            Write-Verbose "Search $($prop.Name)..." 
            $ps = Get-WindowProcesses | Where ProcessName -eq $prop.Name | Select -Unique
            if($ps -ne $Null){
                Write-Verbose "found $Name " 
                $Handle = $ps.MainWindowHandle
                if ( $Handle -eq [System.IntPtr]::Zero ) { continue; }
                
                [int]$x = $prop.Left
                [int]$y = $prop.Top
                [int]$w = $prop.Width
                [int]$h = $prop.Height

                Write-Verbose "setting properties... pos x $x, pos y $y, width $w, height $h" 

                [void][WindowPropertiesExporter]::MoveWindow($Handle, $x, $y, $w, $h, $true)
                [void] [WindowPropertiesExporter]::SetForegroundWindow($Handle) 
            }
        }
    }catch{
        Write-Error "$_"
    }

}


function Get-WindowProcesses{
    [CmdletBinding(SupportsShouldProcess)]
    Param()

    try{
        $ProcessesList = [System.Collections.ArrayList]::new()
        $Processes = Get-Process | Select -Unique
        ForEach($ps in $Processes){
            $MainWindowTitle = $ps.MainWindowTitle.Trim()
            $PsPath = $ps.Path
            if([string]::IsNullOrEmpty($MainWindowTitle)){continue;}    # Don't get processes with empty MainWindowTitle
            if($PsPath.StartsWith("C:\Windows\system32")){continue;}    # Don't get processes located in system32
            if($PsPath.StartsWith("C:\Windows\SystemApps")){continue;}  # Don't get processes located in SystemApps
            [void]$ProcessesList.Add($ps)

        }
        $ProcessesList
    }catch{
        Write-Error "$_"
    }
}


