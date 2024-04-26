#setup the working directory
#please specify the folder you would like to use to keep all your works
setwd("<Enter value>")

#install packages
install.packages("rtweet")

#load the library
library("rtweet")



#copy these values from your twitter app account
my_API_key <- DELETE FOR SECURITY REASONS
my_API_key_secret <- DELETE FOR SECURITY REASONS
my_access_token <- DELETE FOR SECURITY REASONS
my_access_secret <- DELETE FOR SECURITY REASONS

##create token
my_token <-create_token(
  app="MANG6331",
  consumer_key=my_API_key,
  consumer_secret=my_API_key_secret,
  access_token=my_access_token,
  access_secret=my_access_secret, set_renv=FALSE
)
since <- "2020-12-01"
until <- "2021-02-05"

## Not run:
## format datetime for one week ago
toDate <- format(Sys.time() - 60 * 60 * 24 * 7, "%Y%m%d%H%M")
## search 30day for up to 300 rstats tweets sent before the last week
rt <- search_30day("#rstats", n = 300,
                   env_name = "development", toDate = toDate,token = my_token)
## End(Not run)

primevideouk.tweets <- search_fullarchive(
  "@primevideouk", n = 18000, env_name = "testAPI",token = my_token,fromDate = "202012010000", toDate = "202012090000")

primevideouk.tweets <- search_tweets(
  "@primevideouk", n = 18000, include_rts = FALSE,lang="en", token = my_token,since = since, until = until)
primevideouk.tweets <- search_tweets(
  "@primevideouk", n = 18000, include_rts = FALSE,lang="en", token = my_token
)

NetflixUK.tweets <- search_tweets(
  "@Chelsea FC", n = 18000, include_rts = FALSE,lang="en", token = my_token
)

az.tweets <- search_tweets(
  "@amazonUK", n = 1000, include_rts = FALSE,lang="en", token = my_token
)

#have a look at the top three tweets
head(az.tweets,n=3)

#view the screen name of the top 6 tweets
head(az.tweets$screen_name)

#view the text of the top 6 tweets
head(az.tweets$text)
