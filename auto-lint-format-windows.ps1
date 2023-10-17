<#
SystemVerilog Verible Auto Formatter/Linter Powershell Script
Author: Alex Ghandhi
#>

# Update verible-filelist
Write-Host -NoNewline "Updating verible-filelist..."
Get-ChildItem -Path . -Filter *.v -Recurse -Name | %{$_ -replace '.*\.', './$&'} > verible.filelist
Get-ChildItem -Path . -Filter *.sv -Recurse -Name | %{$_ -replace '.*\.', './$&'} >> verible.filelist
Get-ChildItem -Path . -Filter *.svh -Recurse -Name | %{$_ -replace '.*\.', './$&'} >> verible.filelist
Write-Host "Success"

# Skip checks if tools are not present
if( (-not (Get-Command verible-verilog-lint)) -or (-not (Get-Command verible-verilog-format)) ){
    Write-Host "Failed to Locate Verible Toolchain"
    Write-Host "Install Toolchain: https://github.com/chipsalliance/verible"
    Write-Host "Skipping formatter/linter checks"
    Write-Host ""
    Write-Host "Press any key to continue..."
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    Exit 0
}

# Create temporary files to store output and errors
New-Item -Path . -Name scriptOut -ItemType file *> $null
New-Item -Path . -Name scriptError -ItemType file *> $null

##################
# Reformat files #
##################

# Iterate files and run formatter
foreach ($file in Get-Content .\verible.filelist) {
    Write-Host -NoNewline "Reformatting $file..."

    # Check if the file should be ignored
    if (Test-Path -Path '.\verible.filelist.ignore') {
        if (Select-String -Path '.\verible.filelist.ignore' -Pattern $file -SimpleMatch) {
            Write-Host "Skipped"
        }
    } else {
        # Apply user-declared formatter options in .rules.verible_format
        if (Test-Path -Path '.\.rules.verible_format') {
            $params = Get-Content -Raw '.\.rules.verible_format' | %{$_ -replace '\n', ' ' -replace '\r', ''}
        } else {
            $params = ''
        }
        Invoke-Expression "verible-verilog-format $params --inplace $file $file *> scriptOut"
        if (Get-Content .\scriptOut) {
            Write-Host "Failed"
        } else {
            Write-Host "Success"
        }
        Write-Host "" *> scriptOut
    }
}

##############
# Lint Files #
##############

# Iterate files and run linter
foreach ($file in Get-Content .\verible.filelist) {
    Write-Host -NoNewline "Linting $file..."
    # Check if the file should be ignored
    if (Test-Path -Path '.\verible.filelist.ignore') {
        if (Select-String -Path '.\verible.filelist.ignore' -Pattern $file -SimpleMatch) {
            Write-Host "Skipped"
        }
    } else {
        # Apply user-declared linter rules defined in .rules.verible_lint
        Invoke-Expression "verible-verilog-lint --rules_config_search $file *> scriptOut"
        #Get-Content -Path '.\scriptOut'
        if (Get-Content .\scriptOut) {
            Write-Host "Failed"
            Get-Content .\scriptOut *>> scriptError
        } else {
            Write-Host "Success"
        }
        Write-Host "" *> scriptOut
    }
}

# If linter errors were detected, print diagnostics and fail
if (Get-Content '.\scriptError') {
    Write-Host ""
    Write-Host "Failed: Fix the following"
    Write-Host ""
    Get-Content scriptError
    Get-Content scriptError *> autolint_errors.txt
    Remove-Item scriptOut
    Remove-Item scriptError
    Write-Host ""
    Write-Host "Press any key to continue..."
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    Exit 1
}

# No errors detected: Remove temporary files and end the script
Remove-Item scriptOut
Remove-Item scriptError
Write-Host ""
Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
Exit 0
