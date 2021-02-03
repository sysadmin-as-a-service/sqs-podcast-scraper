$r = Invoke-WebRequest -Uri "https://www.occ.net.nz/church-online"
$audioLinks = $r.parsedhtml.documentElement.getElementsByClassName("sqs-audio-embed")

$sermons = @()
foreach($audioLink in $audioLinks){
    $title = (($audioLink.getAttribute("data-title").split("-|:",2)) | Select -Skip 1).Trim()
    $sermonDate = Get-Date ($audioLink.getAttribute("data-title").split("-|:"))[0]
    $sermonDuration = (New-TimeSpan -Start (Get-Date) -End (Get-Date).AddMilliseconds($audioLink.getAttribute("data-duration-in-ms")))

    $sermon = New-Object PSObject -Property @{
        "Title" = $title
        "Date" = $sermonDate
        "Author" = $audioLink.getAttribute("data-author")
        "URL" = $audioLink.getAttribute("data-url")
        "Duration" = $sermonDuration

    }
    $sermons += $sermon
}
$sermons

# now I just need to generate a podcast XML 
# - http://geekswithblogs.net/Lance/archive/2009/04/21/powershellasp-ndash-generate-an-rss-feed-from-powershell-cmdlets.aspx
# - 
# then... host it on azure blob
# then create & schedule an az function to update the xml