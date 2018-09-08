param (
[string]$hostname,
[System.Management.Automation.PSCredential]$Credential
)

if (!$hostname)
{
	$hostname = read-host -prompt "What is the hostname of the new computer?"
}

if (!$Credential)
{
	$Credential = get-credential
}

# map to new host with psdrive if test-connection successful

if (test-connection -computername $hostname -quiet)
{
	new-psdrive -name "P" -root "\\$hostname\c$" -PSProvider "FileSystem" -Credential $Credential
}
else
{
	write-host "the host is not online"
	exit
}

# check that temp folder exists and make hidden

new-item -erroraction ignore -itemtype Directory -path P:\Temp\
$(get-item -path P:\Temp\ -Force).attributes = "Hidden"

if (test-path -path "P:\Temp\Bin\")
{
	remove-item -path P:\Temp\Bin\ -recurse
}
if (test-path -path "P:\Temp\gvim\")
{
	remove-item -path P:\Temp\gvim\ -recurse
}

# copy contents of transfer folder to hidden temp folder

copy-item -path "$PSScriptRoot\Bin\" -Destination "P:\Temp\Bin\" -recurse -Force
copy-item -path "$PSScriptRoot\gvim" -Destination "P:\Temp\gvim\" -recurse -Force
copy-item -path "$PSScriptRoot\Microsoft.Powershell_profile.ps1" -Destination "P:\Windows\System32\WindowsPowershell\v1.0\" -Force

if (test-path -path "P:\Users\besmith2\")
{
	copy-item -path "$PSScriptRoot\vim-files\*" -Destination "P:\Users\besmith2\" -recurse -Force
}

# disconnect psdrive

get-psdrive P | remove-psdrive

# create pssession

$session = new-pssession -computername $hostname -credential $Credential

# add C:\temp\bin to path

invoke-command -session $session -scriptblock {
	if (get-command -name add-path -erroraction silentlycontinue)
	{
		add-path C:\Temp\Bin\
		add-path C:\Temp\gvim\vim80\
	}
	else
	{
		C:\Windows\System32\WindowsPowershell\v1.0\Microsoft.Powershell_profile.ps1
		add-path C:\Temp\Bin\
		add-path C:\Temp\gvim\vim80\
	}
}

# disconnect pssession

remove-pssession -session $session
