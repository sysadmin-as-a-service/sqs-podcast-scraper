param(
    [string]$url
)

$r = Invoke-WebRequest -Uri $url
$audioLinks = $r.parsedhtml.documentElement.getElementsByClassName("sqs-audio-embed")

$podcasts = @()
foreach($audioLink in $audioLinks){
    $title = (($audioLink.getAttribute("data-title").split("-|:",2)) | Select -Skip 1).Trim()
    $podcastDate = Get-Date ($audioLink.getAttribute("data-title").split("-|:"))[0]
    $podcastDuration = (New-TimeSpan -Start (Get-Date) -End (Get-Date).AddMilliseconds($audioLink.getAttribute("data-duration-in-ms")))

    $podcast = New-Object PSObject -Property @{
        "Title" = $title
        "Date" = $podcastDate
        "Author" = $audioLink.getAttribute("data-author")
        "URL" = $audioLink.getAttribute("data-url")
        "Duration" = $podcastDuration

    }
    $podcasts += $podcast
}
$podcasts

# now I just need to generate a podcast XML 
# - http://geekswithblogs.net/Lance/archive/2009/04/21/powershellasp-ndash-generate-an-rss-feed-from-powershell-cmdlets.aspx
# - 
# then... host it on azure blob
# then create & schedule an az function to update the xml