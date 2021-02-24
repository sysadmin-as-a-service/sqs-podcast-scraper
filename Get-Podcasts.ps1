param(
    [string]$url = "https://www.websiteiwanttoscrape.com/audio",
    [string]$blobUrl = "https://myazurestorageacct.blob.core.windows.net/public",
    [string]$podcastImage = "podcast-image.jpg", # 1300x1300 jpg or png https://help.apple.com/itc/podcasts_connect/#/itcb54353390
    [string]$podcastCategory = "Religion &amp; Spirituality", # see https://help.apple.com/itc/podcasts_connect/#/itc9267a2f12
    [string]$podcastAuthor = "Author",
    [string]$podcastFile = "podcast.xml",
    [string]$sasUri = (Get-Content sas-uri.token)
)

Write-Host "Retrieving podcasts from $($url)" -f Yellow

$r = Invoke-WebRequest -Uri $url
$audioLinks = $r.parsedhtml.documentElement.getElementsByClassName("sqs-audio-embed")
$pageTitle = $r.ParsedHtml.documentElement.getElementsByTagName("title")[0].text

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
        "DurationString" = $podcastDuration.ToString('mm\:ss')
        "Duration" = $audioLink.getAttribute("data-duration-in-ms")

    }
    $podcasts += $podcast
}
Write-Host "Parsed $($podcasts.count) episodes." -f Yellow
Write-Host "Building podcast feed XML" -f Yellow

$xml = [xml](Get-Content .\podcast-example.xml)


# channel settings - customize as you please
$xml.rss.channel.title = $pageTitle
$xml.rss.channel.author = $podcastAuthor
$xml.rss.channel.description = "Podcast scraped from $($url)"
$xml.rss.channel.language = "en-us"
$xml.rss.channel.image.childnodes.'#text' = "$($blobUrl)/$podcastImage"
($xml.rss.channel.image.attributes | ? {$_.Name -eq "href"} | select -f 1).'#text' = [string]"$($blobUrl)/$($podcastImage)"
($xml.rss.channel.category.attributes | ? {$_.Name -eq "text"} | select -f 1).'#text' = [string]$podcastCategory
($xml.rss.channel.link.attributes | ? {$_.Name -eq "href" } | select -f 1).'#text' = [string]"$($blobUrl)/podcast.xml"
$xml.rss.channel.pubDate = [string]$podcast.Date.ToString()
$xml.rss.channel.lastBuildDate = [string]$podcast.Date.ToString()

$item = $xml.rss.channel.getElementsByTagName("item")[0]
# podcast episodes
foreach($podcast in $podcasts){

    $podcastItem = $item.Clone()
    $podcastItem.title = [string]"$($podcast.Author) - $($podcast.title)"
    $podcastItem.link = [string]$podcast.URL
    $podcastItem.pubDate = [string]$podcast.Date.ToString()
    $podcastItem.description = [string]"$($podcast.Author) - $($podcast.title). Recorded on $($podcastDate.ToLongDateString())."
    $podcastItem.guid = [string]$podcast.URL
    $podcastItem.explicit = [string]"false"
    $podcastItem.duration = [string]$podcast.DurationString
    $podcastItem.image.href = [string]"$($blobUrl)/$($podcastImage)"
    ($podcastItem.enclosure.attributes | ? {$_.Name -eq "length"}).'#text' = [string]$podcast.Duration
    ($podcastItem.enclosure.attributes | ? {$_.Name -eq "url"}).'#text' = [string]$podcast.URL

    $xml.rss.channel.AppendChild($podcastItem) | Out-Null
}


# remove template podcast
$xml.rss.channel.RemoveChild($item) | Out-Null

# export to new podcast feed
$xmlWriter = new-object System.Xml.XmlTextWriter($podcastFile,$null)
$xmlWriter.Formatting = 'Indented'
$xmlWriter.Indentation = 1
$xmlWriter.IndentChar = "`t"
$xml.WriteTo($xmlWriter)
$xmlWriter.Flush()
$xmlWriter.Close()
Write-Host "Done exporting podcast feed XML" -f Yellow
Write-Host "Pushing podcast feed XML to blob storage" -f Yellow


# now... push to azure blob
$headers = @{
    'x-ms-blob-type' = 'BlockBlob'
    'Content-Type' = 'text/xml'
}

$r = Invoke-RestMethod -Uri $sasUri -Method PUT -Headers $headers -InFile $podcastFile

# then create & schedule an az function to update the xml/push to blob