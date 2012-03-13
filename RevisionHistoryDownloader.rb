require './lib/dropbox_sdk'
require 'pp'
require 'fileutils'
require 'yaml'

=begin
The file allows you to download up to 100 past revisions for every file in a specified dropbox folder. 

Usage: 
  RevisinHistoryDownloader <sourceFolder> <destinationFolder> <maxRevisions>
  
  => sourceFolder:       The dropbox folder (preceded with a slash) tht should be downloaded.
  => destinationFolder:  The local folder into which files should be downloaded (the original dropbox folder structure is maintained).
  => maxRevisions:       [Optional] The maxmimum number of revisions to download (dropbox enforce a max. value of 100)  
=end



ACCESS_TYPE = :dropbox 

SESSION_KEY_FILE='.sessionKey'
SESSION_SECRET_FILE='.sessionSecret'

DEFAULT_MAX_REVISIONS=10

class RevisionHistoryDownloader
    
    appKey = ''
    appSecret = ''
    
    def initialize
        
        config = File.open("appID.yaml") { |yf| YAML::load(yf) }

        appKey = config['APP_KEY']
        appSecret = config['APP_SECRET']

        if appKey == '' or appSecret == ''
            puts "APP_KEY and/or APP_SECRET not found."
            exit
        end

        @session = DropboxSession.new(appKey, appSecret)
        @client = nil
    end

    def login
         # Try and find a previous access token locally.
         if (File.exist?(SESSION_KEY_FILE) && File.exist?(SESSION_SECRET_FILE))
             keyFile = File.open(SESSION_KEY_FILE, 'r') 
             secretFile = File.open(SESSION_SECRET_FILE, 'r')
             @session.set_access_token(keyFile.gets, secretFile.gets) 
         end
        
         unless @session.authorized?
            #Request Access Token from Dropbox
            @session.get_request_token

            authorize_url = @session.get_authorize_url
            
            # Ask user to authorize
            puts "AUTHORIZING", authorize_url, "Please visit that web page and hit 'Allow', then hit Enter here."
            $stdin.gets

            # Get access token from server (which is then stored in @session)
            @session.get_access_token

        end
        
        #Save acccess token for next session.
        File.open(SESSION_KEY_FILE, 'w') {|f| f.write("#{@session.access_token.key}") }
        File.open(SESSION_SECRET_FILE, 'w') {|f| f.write("#{@session.access_token.secret}") }
        
        @client = DropboxClient.new(@session, ACCESS_TYPE)
    end

    def logout(command)
        @session.clear_access_token
        puts "You are logged out."
        @client = nil
    end
    
    def downloadAllRevisions(sourceFolder, destFolder, revLimit=5)
        
        folderListing = ls(sourceFolder)
  
        for item in folderListing
            
            if (item['is_dir'])
                downloadAllRevisions(item['path'], destFolder, revLimit)
            else
                revisions = @client.revisions(item['path'], rev_limit=revLimit)
          
                for revision in revisions
                    downloadRevision(item['path'], createDatedFileName(destFolder + item['path'], revision['modified']), revision['rev'])
                end
             end
        end
        
    end
    
    
    # If revision ID is not specified, current version is returned.
    #dest: full file path including filename.
    def downloadRevision(fileToGet, dest, revisionID)
        
        if !fileToGet || fileToGet.empty?
            puts "please specify item to get"
        elsif !dest || dest.empty?
            puts "please specify full local path to dest, i.e. the file to write to"
        elsif File.exists?(dest)
            puts "error: File #{dest} already exists."
        else
                        
            fileData,metadata = @client.get_file_and_metadata(fileToGet, rev='')
            
            #Create necessary parent directories:
            fileDir, fileNameAndExt = File.split(dest);
            fileName, fileExt = fileNameAndExt.split(/(?=\.)/)
            FileUtils::mkdir_p(fileDir)
                   
           
            #Write to file:
            open(dest, 'w'){|f| f.puts fileData }
            puts "Downloaded file to #{dest}."
        end
    end

    def createDatedFileName(unDatedFileName, lastModifiedDate)
        #Create necessary parent directories:
        fileDir, fileNameAndExt = File.split(unDatedFileName);
        fileName, fileExt = fileNameAndExt.split(/(?=\.)/)
        FileUtils::mkdir_p(fileDir)
               
        #Parse last modified date:
        dateTime = DateTime.strptime(lastModifiedDate, '%a, %d %b %Y %H:%M:%S %z')   
        
        return fileDir + "/" + fileName + "-" + dateTime.strftime('%Y-%m-%d--%H-%M-%S').to_s + fileExt
        
    end
   
    def ls(folder)
        folderClean = '/' + clean_up(folder || '')
        resp = @client.metadata(folderClean)

        return resp['contents']
            
    end

    def clean_up(str)
        return str.gsub(/^\/+/, '') if str
        str
    end
    
     
    def printAccountInfo()
        accountInfo = @client.account_info
        
        puts "############################################"
        puts "Account of: " + accountInfo['display_name']
        puts "Contact Address: " + accountInfo['email']
        puts "############################################"
    end
end


if (ARGV.length < 2)
  puts "There are an insufficient number of arguments." 
  puts "At a minimum you need to specify the dropbox source folder to download and the destination folder for downloads."
  puts "The maximum number of revisions to download can also be specified, though this defaults to 10 if not."
  exit;
end



dropboxSourceFolder = ARGV[0]
localDestinationFolder = ARGV[1]
maxRevisionsToDownload = Integer(ARGV[2])

unless (maxRevisionsToDownload)
  puts "As no 'max revisions' parameter was provided, a maximum of #{DEFAULT_MAX_REVISIONS} revisions will be downloaded."
  maxRevisionsToDownload= DEFAULT_MAX_REVISIONS
else
  #Make sure that this parameter is valid.
  if (maxRevisionsToDownload < 0 || maxRevisionsToDownload > 100)
    puts "An invalid value was provided for the third parameter (max. revisions to download), so the default value will be used (#{DEFAULT_MAX_REVISIONS})"
    maxRevisionsToDownload = DEFAULT_MAX_REVISIONS
  end
end


historyDownloader = RevisionHistoryDownloader.new
historyDownloader.login

historyDownloader.printAccountInfo

historyDownloader.downloadAllRevisions(dropboxSourceFolder, localDestinationFolder, maxRevisionsToDownload)