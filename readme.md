# About

Simple script to scrape a Squarespace website that has a bunch of embedded audio links, convert it into a simple podcast XML file, and push it up to Azure Blob storage.

Use this to scrape a Squarespace website that has a bunch of audio links, but doesn't have a proper podcast. Generate this XML and you'll be able to import it into your favourite podcast player*

*Assuming your favourite podcast player supports importing XML feeds manually. Mine does (Player.fm).

# Usage
Open the script and update the URL, Azure storage container URL, SAS URI, podcast category and author.

The podcastImage you can just copy the one from this repo, and podcastFile you can name whatever you like (but recommend keeping as podcast.xml)

```powershell
param(
    [string]$url = "https://www.websiteiwanttoscrape.com/audio",
    [string]$blobUrl = "https://myazurestorageacct.blob.core.windows.net/public",
    [string]$podcastImage = "podcast-image.jpg", # 1300x1300 jpg or png https://help.apple.com/itc/podcasts_connect/#/itcb54353390
    [string]$podcastCategory = "Religion &amp; Spirituality", # see https://help.apple.com/itc/podcasts_connect/#/itc9267a2f12
    [string]$podcastAuthor = "Author",
    [string]$podcastFile = "podcast.xml",
    [string]$sasUri = (Get-Content sas-uri.token)
)
```
For full instructions, [check out my blog post](https://www.sysadminasaservice.blog)! 
