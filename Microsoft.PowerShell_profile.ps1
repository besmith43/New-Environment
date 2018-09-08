function path-func {$env:path.split(";")}

set-alias l dir -scope "Global"
set-alias get-path path-func -scope "Global"

# Added 'Test-LocalAdmin' function written by Boe Prox to validate is PowerShell prompt is running in Elevated mode 
# Removed lines for correcting path in ADD-PATH 
# Switched Path search to an Array for "Exact Match" searching 
# 2/20/2015 
 
 
Function global:TEST-LocalAdmin() 
    { 
    Return ([security.principal.windowsprincipal] [security.principal.windowsidentity]::GetCurrent()).isinrole([Security.Principal.WindowsBuiltInRole] "Administrator") 
    } 
     
Function global:SET-PATH() 
{ 
[Cmdletbinding(SupportsShouldProcess=$TRUE)] 
param 
( 
[parameter(Mandatory=$True,  
ValueFromPipeline=$True, 
Position=0)] 
[String[]]$NewPath 
) 
 
If ( ! (TEST-LocalAdmin) ) { Write-Host 'Need to RUN AS ADMINISTRATOR first'; Return 1 } 
     
# Update the Environment Path 
 
if ( $PSCmdlet.ShouldProcess($newPath) ) 
{ 
Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH -Value $newPath 
 
# Show what we just did 
 
Return $NewPath 
} 
} 
 
Function global:ADD-PATH() 
{ 
[Cmdletbinding(SupportsShouldProcess=$TRUE)] 
param 
    ( 
    [parameter(Mandatory=$True,  
    ValueFromPipeline=$True, 
    Position=0)] 
    [String[]]$AddedFolder 
    ) 
 
If ( ! (TEST-LocalAdmin) ) { Write-Host 'Need to RUN AS ADMINISTRATOR first'; Return 1 } 
     
# Get the Current Search Path from the Environment keys in the Registry 
 
$OldPath=(Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).Path 
 
# See if a new Folder has been supplied 
 
IF (!$AddedFolder) 
    { Return 'No Folder Supplied.  $ENV:PATH Unchanged' } 
 
# See if the new Folder exists on the File system 
 
IF (!(TEST-PATH $AddedFolder)) 
    { Return 'Folder Does not Exist, Cannot be added to $ENV:PATH' } 
 
# See if the new Folder is already IN the Path 
 
$PathasArray=($Env:PATH).split(';') 
IF ($PathasArray -contains $AddedFolder -or $PathAsArray -contains $AddedFolder+'\') 
    { Return 'Folder already within $ENV:PATH' } 
 
If (!($AddedFolder[-1] -match '\')) { $Newpath=$Newpath+'\'} 
 
# Set the New Path 
 
$NewPath=$OldPath+';'+$AddedFolder 
if ( $PSCmdlet.ShouldProcess($AddedFolder) ) 
{ 
Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH -Value $newPath 
 
# Show our results back to the world 
 
Return $NewPath  
} 
} 
 
FUNCTION GLOBAL:GET-PATH() 
{ 
Return (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).Path 
} 
 


Function global:REMOVE-PATH() 
{ 
[Cmdletbinding(SupportsShouldProcess=$TRUE)] 
param 
( 
[parameter(Mandatory=$True,  
ValueFromPipeline=$True, 
Position=0)] 
[String[]]$RemovedFolder 
) 
 
If ( ! (TEST-LocalAdmin) ) { Write-Host 'Need to RUN AS ADMINISTRATOR first'; Return 1 } 
     
# Get the Current Search Path from the Environment keys in the Registry 
 
$NewPath=(Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).Path 
 
# Verify item exists as an EXACT match before removing 
$Verify=$newpath.split(';') -contains $RemovedFolder 
 
# Find the value to remove, replace it with $NULL.  If it's not found, nothing will change 
 
If ($Verify) { $NewPath=$NewPath.replace($RemovedFolder,$NULL) } 
 
# Clean up garbage from Path 
 
$Newpath=$NewPath.replace(';;',';') 
 
# Update the Environment Path 
if ( $PSCmdlet.ShouldProcess($RemovedFolder) ) 
{ 
Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH -Value $newPath 
 
# Show what we just did 
 
Return $NewPath 
} 
}

function Send-WOL

{

<#

  .SYNOPSIS 

    Send a WOL packet to a broadcast address

  .PARAMETER mac

   The MAC address of the device that need to wake up

  .PARAMETER ip

   The IP address where the WOL packet will be sent to

  .EXAMPLE

   Send-WOL -mac 00:11:22:33:44:55 -ip 192.168.2.100

#>

[CmdletBinding()]

param(

[Parameter(Mandatory=$True,Position=1)]

[string]$mac,

[string]$ip="255.255.255.255",

[int]$port=9

)

$broadcast = [Net.IPAddress]::Parse($ip)

 

$mac=(($mac.replace(":","")).replace("-","")).replace(".","")

$target=0,2,4,6,8,10 | % {[convert]::ToByte($mac.substring($_,2),16)}

$packet = (,[byte]255 * 6) + ($target * 16)

 

$UDPclient = new-Object System.Net.Sockets.UdpClient

$UDPclient.Connect($broadcast,$port)

[void]$UDPclient.Send($packet, 102)

}

