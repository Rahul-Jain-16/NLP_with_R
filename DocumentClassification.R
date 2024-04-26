#setup the working directory
setwd("...")
setwd("C:/Users/ll1d19/Downloads/MANG6331_TM_SMA")
install.packages("naivebayes")
library(naivebayes)

#Activity 1: Multinomial Naive Bayes 
library(tm)
library(SnowballC)

#read a polar data file
pdata <- read.table("amazon_cells_labelled.txt",header=FALSE, sep="\t", fill=TRUE, encoding = "utf-8",quote = "")

#split the data into training and test
traindata <- as.data.frame(pdata[1:700, c(1,2)])
testdata <- as.data.frame(pdata[701:1000,c(1,2)])

#extract the text part only 
trainvector <- as.vector(traindata$V1)
testvector <- as.vector(testdata$V1)

#create corpus for data
traincorpus <- VCorpus(VectorSource(trainvector))
testcorpus <- VCorpus(VectorSource(testvector))

#create the term-by-document matrix
trainmatrix <- DocumentTermMatrix(traincorpus)
testmatrix <- DocumentTermMatrix(testcorpus)

#the Naive Bayes model
nb.model<-naive_bayes(as.matrix(trainmatrix),as.factor(traindata$V2))

#prediction
nb.test.predict<-predict(nb.model,as.matrix(testmatrix))

#confusion matrix
table(nb.test.predict, testdata$V2)

#output the results
#write.csv(nb.results, "NBSummary.csv")


#Activity 2: Support Vector Machine
#the SVM model: using a different package

install.packages('e1071')
install.packages('SparseM')
install.packages('caret')
library(caret)
library(e1071)
library(Matrix)
library(SparseM)

#split into testing and training
set.seed(123)
split<-createDataPartition(pdata$V2, p=0.7, list=FALSE)
traindata<-pdata[split,]
testdata<-pdata[-split,]

#function to deal with unmatched terms
match.matrix<-function(text.col,original.matrix=NULL,weighting=weightTf)
{
  control<-list(weighting=weighting)
  training.col<-
    sapply(as.vector(text.col,mode="character"),iconv,
           to="UTF8",sub="byte")
  corpus<-VCorpus(VectorSource(training.col))
  matrix<-DocumentTermMatrix(corpus,control=control);
  if( !is.null(original.matrix)){
    terms<-
      colnames(original.matrix[,
                                    which(!colnames(original.matrix) %in% colnames(matrix))])
    weight<-0
    if(attr(original.matrix,"weighting")[2]=="tfidf")
      weight <-0.000000001
    amat<-matrix(weight,nrow=nrow(matrix),
                 ncol=length(terms))
    colnames(amat)<-terms
    rownames(amat)<-rownames(matrix)
    fixed<-as.DocumentTermMatrix(
      cbind(matrix[,which(colnames(matrix) %in%
                           colnames(original.matrix))],amat),
      weighting=weighting)
    matrix<-fixed
  }
  matrix<-matrix[,sort(colnames(matrix))]
  gc()
  return(matrix)
}

#function to clean the data

#create a pre-processing function using tm functions and the above two
clean.d<-function(x){
  x<-tolower(x)
  x<-removeWords(x,stopwords('en'))
  x<-removePunctuation(x)
  x<-stripWhitespace(x)
  return(x)
}

#clean the training data and build a term by document matrix
clean.train<-clean.d(traindata$V1)
train.dtm<-match.matrix(clean.train,weighting=tm::weightTfIdf)

train.matrix<-as.matrix(train.dtm)
train.matrix<-Matrix(train.matrix,sparse=T)

SVM.model <- svm(x=train.matrix, y=as.factor(traindata$V2),
                 kernel="linear")

#clean the testing data and build a term by document matrix
clean.test<-clean.d(testdata$V1)
test.dtm<-match.matrix(clean.test,weighting=tm::weightTfIdf,
                       original.matrix=train.dtm )

test.matrix<-as.matrix(test.dtm)
test.matrix<-Matrix(test.matrix,sparse=T)

#apply the model into the testing set and see the results
preds<-predict(SVM.model,as.matrix(test.matrix))
table(preds, testdata$V2)

