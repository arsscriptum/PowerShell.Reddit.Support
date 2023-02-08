# Fan Control using PowerShell

From [this post](https://www.reddit.com/r/PowerShell/comments/10t4cpq/powershell_script_fan_speed_control/) where a user named [defaultaro](https://www.reddit.com/user/defaultaro/) inquired about fan control using powerShell

## Answer

It's possible, I myself use powershell to control the fans speed on my laptop.

Like /u/DoubleFired was noting this is not strictly a powershell based solution. See, the fan control is hardware dependent and very low level (the motherboard handles that and of the software side, it's the computer BIOS, not all BIOS version handles that)
So you need
- Hardware support
- Low level drivers

To depress just yet, fortunately, there is a [very nice, open-source windows tool](https://github.com/hirschmann/nbfc) that can be used to control a laptop fans: ***NOTEBOOK FAN CONTROL***

Link: https://github.com/hirschmann/nbfc	

It supports different configurations so you can set it up to use the specific interupts required by your hardware to control the fans.

1. Install **Notebook Fan Control**   [GITHUB](https://github.com/hirschmann/nbfc) or pre-build at [MAJORGEEKS](https://www.majorgeeks.com/files/details/notebook_fancontrol.html)
2. Select the correct profile configuration for you computer. I personally needed to create my profile from scratch since it wasn't listed.
3. Once you validated that you have the correct configuration, you need to setup Nbfc as a Windows Service.
4. At this point, you are ready to make the PowerShell layer, that is, the scripts to control the fans. 

For the PowerShell side, I didn't over-engineer the shit: 
- I basically have a wrapper on top of ```nbfc.exe``` the NoteBook FanControl CLI client.
- I also parse the output of the ```nbfc.exe``` program.


## FanControl.ps1

Get my [script here](https://github.com/arsscriptum/PowerShell.Reddit.Support/blob/master/FanControl/FanControl.ps1)

Here are the functions I implemented in PowerShell:

- Set-FanSpeed  <<< this is what you want
- Stop-FcService
- Start-FcService
- Get-NotebookFanControlPath
- Get-NotebookFanControlExe
- Push-NotebookFanControlPath
- Get-FcStatus
- Get-FcTemperature
- Get-FcServiceStatus
- Test-Fconfig
- Set-FcConfig
- Set-FcAutoConfig



## PowerShell GUI Application Version

I now just remembered there was more code I wrote relating the the fan control. I was drunk or high and forgot about it. I just re-discovered this beauty.

If you are interested, I could dust it off and sent it your way

![GuiVersion](https://raw.githubusercontent.com/arsscriptum/PowerShell.Reddit.Support/master/FanControl/img/fancontrolform.png)