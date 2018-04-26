Import-Module "${env:ProgramFiles(x86)}\Devolutions\Remote Desktop Manager\RemoteDesktopManager.PowerShellModule.dll"

function Invoke-CreateOracleLinuxRDMSessions {
    $OracleHosts = Get-TervisHostGroupCNAMEAndA -HostGroupName Oracle
    
    $OracleHosts | %{
        $RDMSession = New-RDMSession -TemplateID $RDMTemplate.ID -Host $_.HostName -Name $_.HostName -Type putty -Group $_.EnvironmentName
        Set-RDMSession -Session $RDMSession 
        Update-RDMUI
        Set-RDMSessionProperty -ID $RDMSession.ID -Path MetaInformation -Property OS -Value Linux
    }
}

function New-TervisRDMNodeSession {
    [CmdletBinding()]
    param (
        [parameter(Mandatory,ValueFromPipelineByPropertyName)]$Computername,
        [parameter(Mandatory,ValueFromPipelineByPropertyName)]$SessionName,
        [parameter(Mandatory,ValueFromPipelineByPropertyName)]$EnvironmentName,
        [parameter(Mandatory,ValueFromPipelineByPropertyName)][ValidateSet("Windows Server 2016","CentOS","Linux")]$TemplateName
    )
    if ($TemplateName -eq "Windows Server 2016"){
        $RDMTemplate = Get-RDMTemplate | where name -eq "Windows RDP"
        $SessionType = "RDPConfigured"
    }
    elseif (($TemplateName -eq "CentOS") -or ($TemplateName -eq "Linux")) {
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
        $RDMSessionList = Get-RDMSession
        if ($TemplateName -eq "Windows Server 2016"){
            $RDMTemplate = Get-RDMTemplate | where name -eq "Windows RDP"
            $SessionType = "RDPConfigured"
        }
        elseif (($TemplateName -eq "CentOS") -or ($TemplateName -eq "Linux") -or ($TemplateName -match "OEL")) {
            $RDMTemplate = Get-RDMTemplate | where-object name -eq "Linux Standard"
            $SessionType = "Putty"
        }
        if($RDMSessionList.Name -notcontains $HostSessionName){
            $RDMSession = New-RDMSession -TemplateID $RDMTemplate.ID -Host $Computername -Name $HostSessionName -Type $SessionType -Group $EnvironmentName
            Set-RDMSession -Session $RDMSession 
            Update-RDMUI
            Set-RDMSessionProperty -ID $RDMSession.ID -Path MetaInformation -Property OS -Value $TemplateName
        }

        if($RDMSessionList.Name -notcontains $CNAMESessionName){
            $RDMSession = New-RDMSession -TemplateID $RDMTemplate.ID -Host $Computername -Name $CNAMESessionName -Type $SessionType -Group $EnvironmentName
            Set-RDMSession -Session $RDMSession 
            Update-RDMUI
            Set-RDMSessionProperty -ID $RDMSession.ID -Path MetaInformation -Property OS -Value $TemplateName
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