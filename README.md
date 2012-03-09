### Dropbox Revision History Downloader ###
  
The script allows you to download up to 100 past revisions for every file in a specified dropbox folder. 

Usage: 
  RevisinHistoryDownloader <sourceFolder> <destinationFolder> <maxRevisions>
  
  => sourceFolder:       The dropbox folder (preceded with a slash) tht should be downloaded.
  => destinationFolder:  The local folder into which files should be downloaded (the original dropbox folder structure is maintained).
  => maxRevisions:       The maxmimum number of revisions to download (dropbox enforce a max. value of 100)  

### Requirements ###
The Dropbox API requires that the JSON and OAUTH gems are installed. The following command can be used to do this:
	gem install json oauth

### License ###
This script is released under the MIT license, as is the Dropbox API code itself.