spec = Gem::Specification.new do |s|
  s.name = "dropbox-revs"
  s.version = "1.0"
  s.date = %q{2012-03-12}
  s.authors = ["Angus Macdonald"]
  s.email = %q{amacdonald@aetherworks.com}
  s.summary = %q{Dropbox application which allows user to download the set of previous revisions 
     (the revision history) from all files in a specified folder.}
  s.homepage = %q{https://github.com/angusmacdonald/Dropbox-Revs}
  s.description = %q{Dropbox application which allows user to download the set of previous revisions 
     (the revision history) from all files in a specified folder.}
  s.files = [ "README.md", "RevisionHistoryDownloader.rb", "LICENSE", "lib/dropbox_sdk.rb", "lib/LICENSE", "lib/trusted-certs.crt"]
end