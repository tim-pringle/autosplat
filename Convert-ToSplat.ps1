#requires -Version 2
function ConvertTo-Splat
{

    [CmdletBinding()]
    [OutputType([psobject])]
    param
    (
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [string] $InputObject

    )
    If (!$InputObject) 
    {
        $InputObject = $psISE.CurrentFile.Editor.SelectedText
    }
    $tokens = $null
    $errors = $null
    $ParsedInput = [System.Management.Automation.Language.Parser]::ParseInput($InputObject,[ref]$tokens,[ref]$errors)
    $results = $ParsedInput.FindAll({
            $args[0] -is [System.Management.Automation.Language.CommandElementAst]
    },$true) 
    $splatstring = "`r`n`$paramblock = @{`r`n"
    
    For ($i = 0;$i -lt ($results.count -1);$i = $i+2) 
    {
        $paramName = ($results[$i].Extent) -replace '-', ''
        
        $firstextent = $results[$i].Extent.Text[0]
        $secondextent = $results[$i+1].Extent.Text[0]
     
        If($firstextent -eq $secondextent) 
        {
            $value = '$true'
            $i = $i - 1
        }
        Else 
        {
            $value = $results[$i+1].Extent
            If ($value -notlike '*$*') 
            {
                $value = "`"$value`""
            }
        }
        
        
        $splatstring += "$paramName = $value`r`n"
    }
    
    
    
    
    $splatstring += "}`r`n`r`n"
    $currentLine = $psISE.CurrentFile.Editor.CaretLine
    $psISE.CurrentFile.Editor.InsertText('@paramblock')
    $psISE.CurrentFile.Editor.Select($currentLine,1,$currentLine,1)
    $psISE.CurrentFile.Editor.SetCaretPosition($currentLine,1)
    $psISE.CurrentFile.Editor.InsertText($splatstring)
}



$psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Add('Get Splat', { 
        $text = $psISE.CurrentFile.Editor.SelectedText
        ConvertTo-Splat -InputObject $text
}, 'ALT+T')