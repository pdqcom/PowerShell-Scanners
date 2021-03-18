# https://stackoverflow.com/questions/45716422/powershell-for-checking-reboot-status-after-installing-windows-updates

$Session = New-Object -ComObject "Microsoft.Update.Session"

$Searcher = $Session.CreateUpdateSearcher()

$historyCount = $Searcher.GetTotalHistoryCount()

$Searcher.QueryHistory(0, $historyCount) | Select-Object Date,

   @{name="Operation"; expression={switch($_.operation){

       1 {"Installation"}; 2 {"Uninstallation"}; 3 {"Other"}}}},

   @{name="Status"; expression={switch($_.resultcode){

       1 {"In Progress"}; 2 {"Succeeded"}; 3 {"Succeeded With Errors"};

       4 {"Failed"}; 5 {"Aborted"}

}}}, Title | Out-GridView

$pendingRebootKey = "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
$results = (Get-Item $pendingRebootKey -ErrorAction SilentlyContinue).Property

if($results){
    # Reboot is pending
}