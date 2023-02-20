Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

$s1 = "$PSScriptRoot\light.ps1"
$s2 = "$PSScriptRoot\dark.ps1"
$PowerShellExe = Get-Process | Where Id -eq $Pid | select -ExpandProperty Path
# Create the Label.
$label          = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Size(100, 50)
$label.Size     = New-Object System.Drawing.Size(280, 20)
$label.Font     = New-Object System.Drawing.Font("Lucida",16,[System.Drawing.FontStyle]::Regular)
$label.AutoSize = $true
$label.Text     = "Open in Dark Mode?"

# Create the Yes button.
$yesButton           = New-Object System.Windows.Forms.Button
$yesButton.Location  = New-Object System.Drawing.Size(50, 100)
$yesButton.Size      = New-Object System.Drawing.Size(140, 70)
$yesButton.Font      = New-Object System.Drawing.Font("Lucida",15,[System.Drawing.FontStyle]::Regular)
$yesButton.Text      = "Yes (BLOCKING)"
$yesButton.Add_Click({ 
      $ags = @("-NoProfile", "-NonInteractive",'-File', "$s2")
      Start-Process -FilePath "$PowerShellExe"  -ArgumentList  $ags
    $form.Close() 
})

# Create the No button.
$noButton           = New-Object System.Windows.Forms.Button
$noButton.Location  = New-Object System.Drawing.Size(215, 100)
$noButton.Size      = New-Object System.Drawing.Size(140, 70)
$noButton.Font      = New-Object System.Drawing.Font("Lucida",15,[System.Drawing.FontStyle]::Regular)
$noButton.Text      = "No NON BLOCKING"
$noButton.Add_Click({ 
      $ags = @("-NoProfile", "-NonInteractive",'-File', "$s1")
      Start-Process -FilePath "$PowerShellExe"  -ArgumentList  $ags
    $form.Close()
})

# Create the form.
$form                   = New-Object System.Windows.Forms.Form
$form.Text              = $WindowTitle
$form.Size              = New-Object System.Drawing.Size(400, 220)
$form.FormBorderStyle   = 'FixedSingle'
$form.StartPosition     = "CenterScreen"
$form.AutoSizeMode      = 'GrowAndShrink'
$form.Topmost           = $True
$form.AcceptButton      = $yesButton
$form.CancelButton      = $noButton
$form.ShowInTaskbar     = $true


# Add all of the controls to the form.
$form.Controls.Add($label)
$form.Controls.Add($yesButton)
$form.Controls.Add($noButton)

# Initialize and show the form.
$form.ShowDialog() 