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
        [parameter(Mandatory,ValueFromPipelineByPropertyName)]$EnvironmentName,
        [parameter(Mandatory,ValueFromPipelineByPropertyName)][ValidateSet("Windows Server 2016","CentOS","Linux")]$TemplateName
    )
    if ($OS -eq "Windows Server 2016"){
        $RDMTemplate = Get-RDMTemplate | where name -eq "Windows RDP"
        $SessionType = "RDPConfigured"
    }
    else {
        $RDMTemplate = Get-RDMTemplate | where name -eq "Linux Standard"
        $SessionType = "Putty"
    }
    $RDMSession = New-RDMSession -TemplateID $RDMTemplate.ID -Host $Computername -Name $Computername -Type $SessionType -Group $EnvironmentName
    Set-RDMSession -Session $RDMSession 
    Update-RDMUI
    Set-RDMSessionProperty -ID $RDMSession.ID -Path MetaInformation -Property OS -Value $TemplateName

}