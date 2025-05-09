function Get-FrontMatter {
    <#
    .SYNOPSIS
        Extracts the front matter from a markdown file.

    .DESCRIPTION
        The function extracts the front matter from a markdown file. The front matter is expected to be in YAML format.

    .EXAMPLE
        Get-FrontMatter -File "C:\Temp\test.md"
        This command will return the front matter of the file "C:\Temp\test.md".

    .OUTPUTS
        System.String
    #>
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $true,
            Position = 1,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('File')]
        [string] $FilePath,
        [Parameter(Mandatory = $false)]
        [switch] $Raw
    )
    Process {
        $FrontMatterRegex = Get-FrontMatterRegex
        $FrontMatterDoc = Get-Content $FilePath -Raw

        if ($FrontMatterDoc -match $FrontMatterRegex) {
            $FrontMatter = $Matches[1]
            if ($Raw) {
                return $FrontMatter
            } else {
                return $FrontMatter | ConvertFrom-Yaml -Ordered -ErrorAction Stop
            }
        } else {
            return $null
        }
    }
}

function Get-FrontMatterRegex {
    return '(?smi)^---$(.*)^---'
}

function Remove-FrontMatterFromFile {
    param(
        [string]$FilePath
    )

    $OutFile = New-TemporaryFile
    $FrontMatterRegex = Get-FrontMatterRegex
    $FileContent = Get-Content $FilePath -Raw
    $FileContent = $FileContent -replace $FrontMatterRegex, ''
    $FileContent | Set-Content -Path $OutFile.FullName -Force
    return $OutFile
}

function Get-ProjectOwner {
    return $env:PROJECT_OWNER
}

function Get-ProjectId {
    return $env:PROJECT_ID
}

function Get-RepoOwner {
    return $env:REPO_OWNER
}

function Get-RepoName {
    return $env:REPO_NAME
}

function Get-ProjectUniqueId {
    if (-not $env:PROJECT_UNIQUE_ID) {
        $env:PROJECT_UNIQUE_ID = gh project view (Get-ProjectId) --owner (Get-ProjectOwner) --format json | ConvertFrom-Json | Select-Object -ExpandProperty id
    }

    return $env:PROJECT_UNIQUE_ID
}

function Get-FieldId {
    param(
        [Parameter(Mandatory = $true)]
        [string]$field
    )

    $fieldsFromEnv = $env:PROJECT_FIELD_IDS ? ($env:PROJECT_FIELD_IDS | ConvertFrom-Json -AsHashtable) : @{}
    $fieldsFromEnv = [HashTable]::New($fieldsFromEnv, [StringComparer]::OrdinalIgnoreCase)
    if ($fieldsFromEnv.Keys -contains $field) {
        return $fieldsFromEnv.$field
    } else {
        $data = gh project field-list (Get-ProjectId) --format json --owner (Get-ProjectOwner) | ConvertFrom-Json
        $found = $data.fields | Where-Object { $_.name -eq $field } | Select-Object -First 1
        if (-not $found) {
            Write-Warning "Field with name $field not found in project $(Get-ProjectId)"
        }
        if (-not $found.id) {
            Write-Warning "Field with name $field has no id"
        }

        $fieldsFromEnv.$field = $found.id
        $env:PROJECT_FIELD_IDS = $fieldsFromEnv | ConvertTo-Json -Compress

        return $found.id
    }
}

function Get-FieldType {
    param(
        [Parameter(Mandatory = $true)]
        [string]$field
    )

    $fieldsFromEnv = $env:PROJECT_FIELD_TYPES ? ($env:PROJECT_FIELD_TYPES| ConvertFrom-Json -AsHashtable) : @{}
    $fieldsFromEnv = [HashTable]::New($fieldsFromEnv, [StringComparer]::OrdinalIgnoreCase)
    if ($fieldsFromEnv.Keys -contains $field) {
        return $fieldsFromEnv.$field
    } else {
        $data = gh project field-list (Get-ProjectId) --format json --owner (Get-ProjectOwner) | ConvertFrom-Json
        $found = $data.fields | Where-Object { $_.name -eq $field } | Select-Object -First 1
        if (-not $found) {
            Write-Warning "Field with name $field not found in project $(Get-ProjectId)"
        }
        if (-not $found.type) {
            Write-Warning "Field with name $field has no type"
        }
        
        $fieldsFromEnv.$field = $found.type
        $env:PROJECT_FIELD_TYPES = $fieldsFromEnv | ConvertTo-Json -Compress
        
        return $found.type
    }
}

function Get-SelectionId {
    param(
        $FieldName,
        $OptionName
    ) 

    $selectionIdsFromEnv = $env:PROJECT_SELECTION_IDS ? ($env:PROJECT_SELECTION_IDS | ConvertFrom-Json -AsHashtable) : @{}
    $selectionIdsFromEnv = [HashTable]::New($selectionIdsFromEnv, [StringComparer]::CurrentCultureIgnoreCase)
    try {
        $MatchingField = $selectionIdsFromEnv.Keys | Where-Object { $_ -eq $FieldName } | Select-Object -First 1
        if ($MatchingField) {
            $MatchingOption = $selectionIdsFromEnv.$MatchingField.Keys | Where-Object { $_ -eq $OptionName } | Select-Object -First 1
        }

        if ($MatchingField -and $MatchingOption) {
                return $selectionIdsFromEnv.$MatchingField.$MatchingOption
        }
        else {
            $selectionIdsFromEnv.$FieldName = @{}
            $data = gh project field-list (Get-ProjectId) --format json --owner (Get-ProjectOwner) | ConvertFrom-Json
            $field = $data.fields | Where-Object { $_.name -eq $FieldName } | Select-Object -First 1
            $thisOption = $field.options | Where-Object { $_.name -eq $OptionName } | Select-Object -First 1

            $data.fields | ForEach-Object {
                $fieldName = $_.name
                if($_.options) {
                    $selectionIdsFromEnv.$fieldName = @{}
                    $_.options | ForEach-Object {
                        $OptionName = $_.name
                        $OptionId = $_.id
                        $selectionIdsFromEnv.$fieldName.$OptionName = $OptionId
                    }
                }
            }
            $env:PROJECT_SELECTION_IDS = $selectionIdsFromEnv | ConvertTo-Json -Compress

            return $thisOption.id    
        }
    } catch {
        Write-Error "Failed to get selection id for field $FieldName and option $OptionName : $_"
    }
}

function Get-ProjectItem {
    param(
        [string]$issueUrl
    )

    $AllItems = (gh project item-list (Get-ProjectId) --format json --owner (Get-ProjectOwner) --limit 99999) | ConvertFrom-Json
    $item = $AllItems.items | Where-Object { $_.content.url -eq $issueUrl } | Select-Object -First 1
    if (-not $item) {
        Write-Warning "Issue with url $issueUrl not found in project."
    }
    return $item
}

function Get-NodeIdFromUrl {
    param(
        [string]$url
    )

    return (gh issue view $url --json id | ConvertFrom-Json).id
} 

function Add-SubIssues {
    param(
        [Parameter(ParameterSetName = 'LabelCall', Mandatory = $true)]
        [Parameter(ParameterSetName = 'RecursiveCall', Mandatory = $true)]
        $issueUrl,
        [Parameter(ParameterSetName = 'LabelCall', Mandatory = $true)]
        [Parameter(ParameterSetName = 'Recursive', Mandatory = $false)]
        $labels,
        [Parameter(ParameterSetName = 'LabelCall', Mandatory = $false)]
        [Parameter(ParameterSetName = 'RecursiveCall', Mandatory = $true)]
        $pathToTemplates
    )

    ## Check if the issue exists and has all required fields
    $item = Get-ProjectItem -issueUrl $issueUrl
    if (-not $item) {
        Write-CustomError -message "Issue with url $issueUrl not found in project." -issueUrl $issueUrl -exit
    }
    $ParentNodeId = Get-NodeIdFromUrl -url $issueUrl

    if ($pathToTemplates) {
        Write-Host "Using custom sub-issue template path: $pathToTemplates"

        if (-not (Test-Path -Path $pathToTemplates)) {
            Write-CustomError -message "Sub-issue template path $pathToTemplates not found." -issueUrl $issueUrl
            return $null
        }

        $SubIssueTemplatePaths = @(
            $pathToTemplates
        )
    } else {
        Write-Host 'Using default sub-issue template path.'

        $SubIssueTemplatePaths = $labels | Where-Object { $_ -like 'parent:*' } | ForEach-Object { 
            $SubIssuePath = (Join-Path -Path $PSScriptRoot -ChildPath "../../CUSTOM_SUBISSUE_TEMPLATES/$($_)")
            if (-not (Test-Path -Path $SubIssuePath)) {
                Write-CustomError -message "Sub-issue template path $SubIssuePath not found." -issueUrl $issueUrl
                return $null
            }
            return $SubIssuePath
        } | Where-Object { $_ -ne $null }
    }

    foreach ($TemplatePath in $SubIssueTemplatePaths) {
        
        $SubIssuesToProcess = Get-ChildItem -Path $TemplatePath -Filter '*.md' | Sort-Object -Property BaseName

        foreach ($SubIssue in $SubIssuesToProcess) {
            Write-Host "Processing sub-issue template: $($SubIssue.FullName)"
                
            $FrontMatter = Get-FrontMatter -FilePath $SubIssue.FullName
            $NoFrontMatterIssueBodyFilePath = Remove-FrontMatterFromFile -FilePath $SubIssue.FullName

            $ConcatenatedTitle = "$($item.title) - $($FrontMatter.title)"
            $CreatedSubIssue = Add-Issue -title $ConcatenatedTitle -bodyFilePath $NoFrontMatterIssueBodyFilePath.FullName -ProjectFields $FrontMatter.fields -Labels $FrontMatter.labels -Assignees $FrontMatter.assignees -Milestones $FrontMatter.milestones
            try {
                Set-SubIssue -ParentNodeId $ParentNodeId -ChildNodeId $CreatedSubIssue.issueNodeId
            } catch {
                Write-CustomError -message "Failed to link sub-issue $($CreatedSubIssue.issueNodeId) to parent issue $ParentNodeId : $_" -issueUrl $issueUrl
            }

            $MatchingFolder = Get-ChildItem -Path $TemplatePath -Directory | Where-Object { $_.BaseName -eq $SubIssue.BaseName } | Select-Object -First 1
            if ($MatchingFolder) {
                Add-SubIssues -issueUrl $CreatedSubIssue.issueUrl -pathToTemplates $MatchingFolder.FullName
            }
        }
    }
}

function Add-Issue {
    param(
        [string]$Repo = "$(Get-RepoOwner)/$(Get-RepoName)",
        [string]$Title,
        [string]$BodyFilePath,
        [hashtable]$ProjectFields,
        [string[]]$Assignees = @(),
        [string[]]$Labels = @(),
        [string[]]$Milestones = @()
    )

    try {
        $issueUrl = gh issue create --repo $repo --title "$title" --body-file $bodyFilePath --assignee "$($Assignees -join ',')" --label "$($Labels -join ',')" --milestone "$($Milestones -join ',')"
        if ($LastExitCode -ne 0) {
            throw 'gh cli error'
        }
        $issueNodeId = (gh issue view $issueUrl --json id | ConvertFrom-Json).id
        Write-Host "[$title] Issue created: $($issueUrl), now adding to project"
        $item = gh project item-add (Get-ProjectId) --owner (Get-ProjectOwner) --url $issueUrl --format 'json' | ConvertFrom-Json
        $itemId = $item.id
        $FieldNames = $ProjectFields.Keys
        Write-Host "[$title] Added to the project, now setting fields $($FieldNames -join ', ')"
        foreach ($Fieldname in $FieldNames) {
            $IsDate = $ProjectFields[$Fieldname].Keys -contains 'type' ? $ProjectFields[$Fieldname].type -eq 'date' : $false
            Set-Field -item $item -FieldName $Fieldname -FieldValue $ProjectFields[$Fieldname].Value -isDate $IsDate
        }
        # TODO: Set issue type! (02/25: Public preview)
        return @{
            'itemId'      = $itemId
            'issueUrl'    = $issueUrl
            'issueNodeId' = $issueNodeId
        }
    } catch {
        Write-CustomError -message "Failed to create issue $Title : $_" -exit -issueUrl $issueUrl
    }
}

function Set-SubIssue {
    param(
        $ParentNodeId,
        $ChildNodeId
    )

    try {
        # Add the sub-issue to the parent issue
        $Response = gh api graphql -H GraphQL-Features:issue_types -H GraphQL-Features:sub_issues -f parentIssueId="$ParentNodeId" -f childIssueId="$ChildNodeId" -f query='
        mutation($parentIssueId: ID!, $childIssueId: ID!) {
        addSubIssue(input: { issueId: $parentIssueId, subIssueId: $childIssueId }) {
            issue {
            title
            number
            url
            id
            issueType {
                name
            }
            }
            subIssue {
            title
            number
            url
            id
            issueType {
                name
            }
            }
        }
        }'
    } catch {
        Write-Information "Response: $Response"
        Write-CustomError -message "Failed to link sub-issue $ChildNodeId to parent issue $ParentNodeId : $_"
    }
}

function Get-SubIssues {
    param(
        [string]$ParentNodeId
    )

    try {
        $SubIssues = (gh api graphql -H GraphQL-Features:issue_types -H GraphQL-Features:sub_issues -f issueId="$ParentNodeId" -f query='
            query($issueId: ID!) {
                node(id: $issueId) {
                    ... on Issue {
                        subIssues(first: 100) {
                            nodes {
                                title
                                number
                                url
                                id
                            }
                        }
                    }
                }
            }'
        )
        return ($SubIssues | ConvertFrom-Json).data.node.subIssues.nodes
    } catch {
        Write-Error "Failed to get sub-issues for parent issue $ParentNodeId : $_"
    }
}

function Get-ParentItem {
    param(
        [string]$ChildNodeId
    )

    $Parent = Get-ParentIssue -ChildNodeId $ChildNodeId
    if (-not $Parent) {
        Write-Error "Parent issue not found for child issue $ChildNodeId"
        return
    }
    $ParentItem = Get-ProjectItem -issueUrl $Parent.url
    if (-not $ParentItem) {
        Write-Error "Parent issue with url $($Parent.url) not found in project."
        return
    }
    return $ParentItem
}

function Get-ParentIssue {
    param(
        [string]$ChildNodeId
    )

    try {
        $Parent = (gh api graphql -H GraphQL-Features:sub_issues -H GraphQL-Features:issue_types -f issueId="$ChildNodeId" -f query='
            query($issueId: ID!) {
                node(id: $issueId) {
                    ... on Issue {
                        parent {
                            title
                            number
                            url
                            id
                            issueType {
                            name
                            }
                        }
                    }
                }
            }'
        )
        return ($Parent | ConvertFrom-Json).data.node.parent
    } catch {
        Write-Error "Failed to get parent issue for child issue $ChildNodeId : $_"
    }
    
}

function Get-AutomationConfigFromItem {
    param(
        [object]$item
    )
    try {
        $found = $item.automation
        if (-not $found) {
            Write-Warning "Automation config not found in item $($item.id)"
        }
        $foundHashTable = $found | ConvertFrom-Json -AsHashtable
        return $foundHashTable
    } catch {
        Write-CustomError -message "Failed to get automation config from item $($item.id) : $_" -exit -issueUrl $item.content.url
    }
}

function Set-Field {
    param(
        [object]$item,
        [string]$FieldName,
        [string]$FieldValue,
        [boolean]$isDate = $false
    )

    $FieldId = Get-FieldId -field $FieldName
    if (-not $FieldId) {
        Write-CustomError -message "Field with name $FieldName not found in project $(Get-ProjectId)" -exit -issueUrl $item.content.url
    }

    $FieldType = Get-FieldType -field $FieldName

    try {
        switch ($FieldType) {
            'ProjectV2SingleSelectField' {
                $SelectionId = Get-SelectionId -FieldName $FieldName -OptionName $FieldValue
                if (-not $SelectionId) {
                    Write-CustomError -message "Selection with name $FieldValue not found in field $FieldName" -exit -issueUrl $item.content.url
                }
                gh project item-edit --id "$($item.id)" --field-id $FieldId --project-id (Get-ProjectUniqueId) --single-select-option-id ($SelectionId)
                return
            }
            Default {
                if ($isDate) {
                    gh project item-edit --id "$($item.id)" --field-id $FieldId --project-id (Get-ProjectUniqueId) --date $FieldValue
                } else {
                    gh project item-edit --id "$($item.id)" --field-id $FieldId --project-id (Get-ProjectUniqueId) --text $FieldValue
                }
            }
        }
    } catch {
        Write-CustomError -message "Failed to set field $FieldName with value $FieldValue in item $($item.id) : $_" -exit -issueUrl $item.content.url
    }
}

function Invoke-Automations {
    param(
        [Parameter(Mandatory = $true)]
        [string]$url,
        [Parameter(Mandatory = $true)]
        [object[]]$Automations
    )

    $item = Get-ProjectItem -issueUrl $url
    if (-not $item) {
        Write-CustomError -message "Issue with url $url not found in project." -issueUrl $url -exit
    }

    foreach ($Automation in $Automations) {
        $Action = $Automation.action
        if (-not $Action) {
            Write-CustomError -message "Automation action not found in item $($item.id)" -issueUrl $url -exit
        }

        $Targets = $Automation.targets
        if (-not $Targets) {
            Write-CustomError -message "Automation targets not found in item $($item.id)" -issueUrl $url -exit
        }

        $ActionType = $Action.type
        if (-not $ActionType) {
            Write-CustomError -message "Automation action type not found in item $($item.id)" -issueUrl $url -exit
        }

        $NodeId = Get-NodeIdFromUrl -url $url

        switch ($ActionType) {
            'set-field' {
                $FieldName = $Action.field
                if (-not $FieldName) {
                    Write-CustomError -message "Automation field name not found in item $($item.id)" -issueUrl $url -exit
                }
                
                $FieldValue = $Action.value
                if (-not $FieldValue) {
                    Write-CustomError -message "Automation field value not found in item $($item.id)" -issueUrl $url -exit
                }

                foreach ($Target in $Targets) {
                    if ($Target -eq 'parent') {
                        $ParentItem = Get-ParentItem -ChildNodeId $NodeId
                        if (-not $ParentItem) {
                            Write-CustomError -message "Parent item not found for item $($item.id)" -issueUrl $url -exit
                        }
                        $TargetItems = @($ParentItem)
                    } elseif ($Target -eq 'sub-issues') {
                        $SubIssues = Get-SubIssues -ParentNodeId $NodeId
                        $TargetItems = @($SubIssues | ForEach-Object {
                                $SubIssueItem = Get-ProjectItem -issueUrl $_.url
                                if (-not $SubIssueItem) {
                                    Write-CustomError -message "Sub-issue with url $($_.url) not found in project." -issueUrl $url -exit
                                }
                                return $SubIssueItem
                            })
                    } elseif ($Target -eq 'self') {
                        $TargetItems = @($item)
                    }
                    foreach ($TargetItem in $TargetItems) {
                        try {
                            Set-Field -item $TargetItem -FieldName $FieldName -FieldValue $FieldValue
                        } catch {
                            Write-CustomError -message "Failed to set field $FieldName with value $FieldValue in item $($TargetItem.id) : $_" -issueUrl $url
                        }
                    }
                }
            }
            Default {
                Write-CustomError -message "Unknown action type: $ActionType" -issueUrl $url -exit
            }
        }
    }
}

function Invoke-AutomationsWithTrigger {
    param(
        [Parameter(Mandatory = $true)]
        [string]$url,
        [Parameter(Mandatory = $true)]
        [string]$trigger
    )

    ## Check if the issue exists and has all required fields
    $item = Get-ProjectItem -issueUrl $url

    if (-not $item) {
        Write-CustomError -message "Issue with url $url not found in project." -issueUrl $url -exit
    }

    $AutomationConfig = Get-AutomationConfigFromItem -item $item

    $ApplicableAutomations = $AutomationConfig | Where-Object { $_.trigger -eq $trigger }
    Invoke-Automations -Automations $ApplicableAutomations -url $url
}

function Write-CustomError {
    param(
        [string]$message,
        [Parameter(Mandatory = $false)]
        [string]$issueUrl,
        [switch]$exit
    )

    $body = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [ERROR] [better-project-automation] $message"
    if ($issueUrl) {
        if (-not $env:SILENT_ERRORS) {
            gh issue comment $issueUrl --body $body       
        }
    }
    
    Write-Error $message
    
    if ($exit) {
        exit 1
    }
}