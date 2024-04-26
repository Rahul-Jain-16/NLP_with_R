#setup the working directory
setwd("//...")

#import the necessary packages
install.packages("stringr")
install.packages("qdap")
install.packages("tm") 
install.packages("mgsub")
install.packages("stopwords")

#load the library
library(stringr)
library(qdap)
library(tm)
library(wordcloud)
library(mgsub)
library(stopwords)
library(ggplot2)

#Set Options
options(stringasfactors=F)

#keep a backup version before pre-processing
az.tweets.bkup<-az.tweets 

#overview on the top six tweets
head(az.tweets$text)

#replace all @amazonUK with @aUK
az.tweets$text<-gsub('@amazonUK', '@aUK', az.tweets$text, ignore.case=T)
head(az.tweets$text)

#replace the words listed in "to.be.replace" by those listed in "replacement"
to.be.replace <-c('next day delivery', 'wish list', 'wishlist')
replace.by <-c('next-day-delivery','wish-list','wish-list')
az.tweets$text<-mgsub(az.tweets$text, to.be.replace, replace.by )


#tailor-made a few things

#A function changes all to lower case (and return NA stead of error if it is a special character)
#Return NA instead of tolower error
tryTolower <-function(x){
  #return NA when there is an error
  y=NA
  #tryCatch error
  try_error=tryCatch(tolower(x),error=function(e) e)
  #if not an error 
  if (!inherits(try_error, 'error'))
    y=tolower(x)
  return(y)
}

#create my stop words list
custom.stopwords<-c(stopwords('english'),'lol')

#create a pre-processing function using tm functions and the above two
clean.corpus<-function(corpus){
  corpus<-tm_map(corpus,content_transformer(tryTolower))
  corpus<-tm_map(corpus,removeWords,custom.stopwords)
  corpus<-tm_map(corpus,removePunctuation)
  corpus<-tm_map(corpus,stripWhitespace)
  corpus<-tm_map(corpus,removeNumbers)
  corpus<-tm_map(corpus,stemDocument, language = "english")
  return(corpus)
}

#define the tweets object
the.corpus <- VCorpus(VectorSource(az.tweets$text))

#clean the tweets with the function created earlier
the.corpus<-clean.corpus(the.corpus)

#Create the term document matrix
tdm <- DocumentTermMatrix(the.corpus,control=list(weighting=weightTf))

#remove sparse terms from a doucment if the sparsity is more than 99%
tdm.n<-removeSparseTerms(tdm, 0.99)

#redefine it as matrix for easy to computation
tdm.tweets<-as.matrix(tdm.n)

#save the pre-processed document term matrix
saveRDS(tdm.tweets, file="matrix.tweets")

#check dimension of the tweets
dim(tdm.tweets)

#check subset of the tweets
tdm.tweets[200:210,1:15]

#check term frequency
term.freq<-colSums(tdm.tweets)

#create a dataframe with the term and then the frequency as the second column
freq.df<-data.frame(word=names(term.freq),frequency=term.freq)
freq.df<-freq.df[order(freq.df[,2],decreasing=T),]
freq.df[1:20,]

#Plot word frequencies when frequency is higher than 30
hp <- ggplot(subset(freq.df, freq.df$frequency>30), aes(word, frequency))    
hp <- hp + geom_bar(stat="identity")   
hp <- hp + theme(axis.text.x=element_text(angle=45, hjust=1))   
hp   

#create a word cloud and maximum number of words are 50
wordcloud(freq.df$word,freq.df$frequency,max.words=50)
