# create a new queue
$namespaces = [System.Collections.Queue]::new()

# add an initial namespace to the queue
# any namespace in the queue will later be processed
$namespaces.Enqueue('root')

# process all elements on the queue until all are taken
While ($namespaces.Count -gt 0 -and ($current = $namespaces.Dequeue()))
{
    # find child namespaces
    Get-CimInstance -Namespace $current -ClassName __Namespace -ErrorAction Ignore |
    # ignore localization namespaces
    Where-Object Name -NotMatch '^ms_\d{2}' |
    ForEach-Object {
        # construct the full namespace name
        $childnamespace = '{0}\{1}' -f $current, $_.Name
        # add namespace to queue
        $namespaces.Enqueue($childnamespace)
    }

    # output current namespace
    $current
}