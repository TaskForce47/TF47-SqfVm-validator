$testfolder = $args[0]
if([string]::IsNullOrEmpty($testfolder)) {
    Write-Error "[ACTION ERROR] Didn't specified testfolder..."
    Exit -1
}
if(! (Test-Path ($testfolder))) {
    Write-Error "[ACTION ERROR] Folder doesn't exist..."
    Exit -1
}


$sqfVm = "$PSScriptRoot\sqfvm\SQF-VM - Win64 - x64\sqfvm.exe"
if(! (Test-Path ($sqfVm))) {
    $url = "https://github.com/SQFvm/vm/releases/download/1.3.2-RC1/1.3.2.RC1-Win64-x64.zip"
    $temp = "$PSScriptRoot\sqfvm.zip"
    Invoke-WebRequest -Uri $url -OutFile $temp
    Expand-Archive -LiteralPath $temp -DestinationPath "$PSScriptRoot\sqfvm"
    Remove-Item -path $temp
    Write-Output "Extracted to $sqfvm"
}
else
{
    Write-Output "SqfVm found successful"
}

$sqfFiles = Get-ChildItem -Path "$testfolder\*.sqf" -Recurse -Force
$configFiles = Get-ChildItem -Path "$testfolder\*.hpp" -Recurse -Force
$testFiles = $sqfFiles + $configFiles


#Write-Output $sqfFiles
$failed = $false;
$errorCount = 0;

foreach ($file in $testFiles) {
    Write-Output "Testing file $file"
    $vm = New-Object System.Diagnostics.ProcessStartInfo
    $vm.FileName = $sqfVm
    $vm.Arguments = "-a --no-execute-print --parse-only --load $testfolder -i $file --disable-macro-warnings"
    $vm.UseShellExecute = $false
    $vm.RedirectStandardError = $true
    $vm.RedirectStandardOutput = $true
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $vm
    $process.Start() > $null
    $process.WaitForExit();
    if($process.ExitCode -ne 0) {
        $errorCount = $errorCount + 1;
        $failed = $true
    } else {
        Write-Output "Passed!"
    }
    $output = $process.StandardError.ReadToEnd()
    if($output) {
        Write-Warning $output
    }
}

if($failed) {
    Write-Error "[TEST FAILED] Some scripts did not pass the test! Errors: $errorCount"
    Exit -1
} else {
    Write-Output "[TEST SUCCESSFUL] No errors where found!"
    Exit 0
}