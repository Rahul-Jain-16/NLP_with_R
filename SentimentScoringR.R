#Please setup the working directory
setwd("C:/Users/ll1d19/Downloads/MANG6331_TM_SMA")

#Sentiment Scoring

#The first approach
install.packages("twitteR")
library(twitteR)
library(tm)

#retreat the saved tweets from the "Downloading Tweets Lab Session"
az.tweets<-readRDS("data.az")


az.text <- az.tweets$text
#------------------------------------------------------------------

#loading Hu Liu's opinion lexicon
hu.liu.pos <- scan("positive-words.txt",what="character", comment.char="");
hu.liu.neg <- scan("negative-words.txt",what="character", comment.char="");

#loading some industry-specific and/or especially emphatic terms
pos.words <- c(hu.liu.pos, 'prize')
neg.words <- c(hu.liu.neg, 'late')

#function for the score.sentiment
score.sentiment = function(sentences, pos.words, neg.words, .progress='none')
{
  require(plyr)
  require(stringr)
  
  # we got a vector of sentences. plyr will handle a list
  # or a vector as an "l" for us
  # we want a simple array ("a") of scores back, so we use 
  # "l" + "a" + "ply" = "laply":
  scores = laply(sentences, function(sentence, pos.words, neg.words) {
    
    # clean up sentences with R's regex-driven global substitute, gsub():
    sentence = gsub('[[:punct:]]', '', sentence)
    sentence = gsub('[[:cntrl:]]', '', sentence)
    sentence = gsub('\\d+', '', sentence)
    # and convert to lower case:
    sentence = tolower(sentence)
    
    # split into words. str_split is in the stringr package
    word.list = str_split(sentence, '\\s+')
    # sometimes a list() is one level of hierarchy too much
    words = unlist(word.list)
    
    # compare our words to the dictionaries of positive & negative terms
    pos.matches = match(words, pos.words)
    neg.matches = match(words, neg.words)
    
    # match() returns the position of the matched term or NA
    # we just want a TRUE/FALSE:
    pos.matches = !is.na(pos.matches)
    neg.matches = !is.na(neg.matches)
    
    # and conveniently enough, TRUE/FALSE will be treated as 1/0 by sum():
    score = sum(pos.matches) - sum(neg.matches)
    
    return(score)
  }, pos.words, neg.words, .progress=.progress )
  
  scores.df = data.frame(score=scores, text=sentences)
  return(scores.df)
}


#testing the score.function by some tweets
mysample=c("You're awesome and I love you", "i hate and hate and hate. so angry. die!")
result=score.sentiment(mysample, pos.words, neg.words)
class(result)
result$score


#score the tweets
az.scores=score.sentiment(az.text,pos.words,neg.words,.progress='text')
class(az.scores)

#save the score in a csv file
write.csv(az.scores, "az_scores.csv")

################################################################################
#The second approach
#use the polarity function in the package qdap
#please install and load the package

library(qdap)
library(ggplot2)
library(ggthemes)
library(wordcloud)

#the key.pol is a dataset in qdap keeping some polarity words
#here we are going to extract this list but also add some new words
pos.new<-c('lol','rofl')
pos.old<-subset(as.data.frame(key.pol),key.pol$y==1)
pos.words<-c(pos.new,pos.old[,1])
neg.new<-c('meh','kappa')
neg.old<-subset(as.data.frame(key.pol),key.pol$y==-1)
neg.words<-c(neg.new,neg.old[,1])
all.polarity<-sentiment_frame(pos.words,neg.words,1,-1)

#check the polarity using a sentence
#the function calculate using the following function
#sum(positive+negative+amplifier)/sqrt(number of words)
polarity('it is good',polarity.frame=all.polarity)
polarity('It is very good',polarity.frame=all.polarity)
polarity('it is bad',polarity.frame=all.polarity)
polarity('It is very bad',polarity.frame=all.polarity)

#read a file containing 1,000 airbnb reviews about stays in Boston
options(stringsAsFactors=F)
bos.airbnb<-read.csv('bos_airbnb_1k.csv')

bos.pol<-polarity(bos.airbnb$comments)

#plot the histogram of the polarity
ggplot(bos.pol$all,aes(x=polarity,y=..density..))+theme_gdocs()+
  geom_histogram(binwidth = .25,
                 fill="darkred", colour="grey60", size=.2) + 
  geom_density(size=.75)

#save the polarity back to the orginial dataset
bos.airbnb$polarity<-scale(bos.pol$all$polarity)

#plotting wordclouds (one for positive and one for negative)

pos.comments<-subset(bos.airbnb$comments,bos.airbnb$polarity>0)
neg.comments<-subset(bos.airbnb$comments,bos.airbnb$polarity<0)

#compress it into a document with only two components
#(one for positive and one for negative)
pos.terms<-paste(pos.comments, collapse=" ")
neg.terms<-paste(neg.comments, collapse=" ")
all.terms<-c(pos.terms,neg.terms)
all.corpus<-VCorpus(VectorSource(all.terms))

#create the term by document matrix using tfidf
all.tdm<-TermDocumentMatrix(all.corpus,
                            control=list(weighting=weightTf,
                                         removePunctuation=TRUE, 
                                         stopwords=stopwords(kind='en')))

#switch to matrix and add column names
all.tdm.m<-as.matrix(all.tdm)
colnames(all.tdm.m)<-c('positive','negative')

#build wordclouds
comparison.cloud(all.tdm.m,max.words=100)
colors=c('darkgreen','darkpurple')
