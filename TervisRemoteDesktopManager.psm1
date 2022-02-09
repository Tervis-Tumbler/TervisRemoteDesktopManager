Import-Module "${env:ProgramFiles(x86)}\Devolutions\Remote Desktop Manager\RemoteDesktopManager.PowerShellModule.psd1"

function Invoke-CreateOracleLinuxRDMSessions {
    $OracleHosts = Get-TervisHostGroupCNAMEAndA -HostGroupName Oracle
    
    $OracleHosts | % {
        $RDMSession = New-RDMSession -TemplateID $RDMTemplate.ID -Host $_.HostName -Name $_.HostName -Type putty -Group $_.EnvironmentName
        Set-RDMSession -Session $RDMSession 
        Update-RDMUI
        Set-RDMSessionProperty -ID $RDMSession.ID -Path MetaInformation -Property OS -Value Linux
    }
}

function Get-TervisRDMDataSource {
    Get-RDMDataSource |
    Where Type -eq SQLServer
}

function New-TervisRDMNodeSession {
    [CmdletBinding()]
    param (
        [parameter(Mandatory,ValueFromPipelineByPropertyName)]$Computername,
        [parameter(Mandatory,ValueFromPipelineByPropertyName)]$SessionName,
        [parameter(Mandatory,ValueFromPipelineByPropertyName)]$EnvironmentName,
        [parameter(Mandatory,ValueFromPipelineByPropertyName)]$TemplateName
    )
    Get-TervisRDMDataSource | Set-RDMCurrentDataSource
    if ($TemplateName -match "Windows Server") {
        $RDMTemplate = Get-RDMTemplate | where name -eq "Windows RDP"
        $SessionType = "RDPConfigured"
    }
    elseif (($TemplateName -in "Cent OS", "Linux", "ArchLinux", "Debian 9") -or ($TemplateName -match "OEL")) {
        $RDMTemplate = Get-RDMTemplate | where-object name -eq "Linux Standard"
        $SessionType = "Putty"
    }
    $RDMSession = New-RDMSession -TemplateID $RDMTemplate.ID -Host $Computername -Name $SessionName -Type $SessionType -Group $EnvironmentName
    Set-RDMSession -Session $RDMSession 
    Update-RDMUI
    Set-RDMSessionProperty -ID $RDMSession.ID -Path MetaInformation -Property OS -Value $TemplateName
}

function New-TervisApplicationNodeRDMSession {
    [CmdletBinding()]
    param (
        [parameter(Mandatory,ValueFromPipelineByPropertyName)]$ComputerName,
        [parameter(Mandatory,ValueFromPipelineByPropertyName)]$EnvironmentName,
        [parameter(Mandatory,ValueFromPipelineByPropertyName)]$ApplicationName
    )
    Process {
        $ApplicationDefinition = Get-TervisApplicationDefinition -Name $ApplicationName
        $TemplateName = $ApplicationDefinition.VMOperatingSystemTemplateName
        $HostSessionName = $ComputerName + ".tervis.prv"
        $CNAMESessionName = $ApplicationName + ".$EnvironmentName" + ".tervis.prv"
        
        Get-TervisRDMDataSource | Set-RDMCurrentDataSource
        $RDMSessionList = Get-RDMSession
        
        $HostSessionName, $CNAMESessionName |
        Where-Object { $RDMSessionList.Name -notcontains $_ } |
        ForEach-Object {
            New-TervisRDMNodeSession -TemplateName $TemplateName -Computername $Computername -SessionName $_ -EnvironmentName $EnvironmentName
        }
    }
}

function Remove-TervisApplicationNodeRDMSession {
    [CmdletBinding()]
    param (
        [parameter(Mandatory,ValueFromPipelineByPropertyName)]$ComputerName
    )
    Process {
        $HostSessionName = $ComputerName + ".tervis.prv"
        $RDMSessionList = Get-RDMSession
        if($RDMSessionList.Name -contains $HostSessionName){
            $RDMSession = Get-RDMSession -Name $HostSessionName
            Remove-RDMSession -ID $RDMSession.ID
            Update-RDMUI
        }
    }
}