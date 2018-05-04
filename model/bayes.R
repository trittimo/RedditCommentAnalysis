library(gmodels)
library(e1071)
library(stringi)
library(SnowballC)
library(tm)
library(data.table)

# Expected data format:
# author,body,score,depth,subreddit,permalink,max_score_at_depth

# CONSTANTS
TRAINING_RATIO <- 0.75
FREQUENCY_ELIMINATION <- 4

# Import our data
reddit <- read.csv("aww.csv", stringsAsFactors = FALSE)
senticnet <- read.csv("senticnet.csv", stringsAsFactors = FALSE)

# Types of analysis we can do:
#   Point prediction
#   Positivity rating

# Breakdown of point prediction
# Point values have been split into four categories:
#   negative: points <= 0,
#   low: points / maxscore_at_depth <= 0.3
#   medium: points / maxscore_at_depth <= 0.8
#   high: points / maxscore_at_depth > 0.8
# We're using naive bayes to predict which of these categories a comment will fall in

# Classify positivity as positive or negative
senticnet$classified_score <- cut(senticnet$score, breaks = c(-1, 0, 1), right = FALSE, labels = c("Positive", "Negative"))

# Determine the points ratio
reddit$points_ratio <- reddit$score / reddit$max_score_at_depth

# Classify points as negative, low, medium, high
reddit$classified_points <- cut(reddit$points_ratio,
                                breaks = c(-1, 0, 0.3, 0.8, 1),
                                right = FALSE,
                                labels = c("negative", "low", "medium", "high"))

# Prepare our reddit comments for analysis
reddit_corpus <- VCorpus(VectorSource(reddit$body))
reddit_corpus_clean <- tm_map(reddit_corpus, content_transformer(tolower))
reddit_corpus_clean <- tm_map(reddit_corpus_clean, content_transformer(stri_escape_unicode))
reddit_corpus_clean <- tm_map(reddit_corpus_clean, removeWords, stopwords())
reddit_corpus_clean <- tm_map(reddit_corpus_clean, removePunctuation)
reddit_corpus_clean <- tm_map(reddit_corpus_clean, stemDocument)
reddit_corpus_clean <- tm_map(reddit_corpus_clean, stripWhitespace)
reddit_dtm <- DocumentTermMatrix(reddit_corpus_clean)

# Define the sizes of our datasets
train_size <- round(TRAINING_RATIO * nrow(reddit))

# Create the training dataset
reddit_dtm_train <- reddit_dtm[1:train_size, ]
reddit_dtm_test <- reddit_dtm[train_size:nrow(reddit), ]

reddit_train_labels <- reddit[1:train_size, ]$classified_points
reddit_test_labels <- reddit[train_size:nrow(reddit), ]$classified_points

# Eliminate words that don't appear in many comments
# TODO: Adjust this value as need
reddit_freq_terms <- findFreqTerms(reddit_dtm_train, FREQUENCY_ELIMINATION)
reddit_dtm_freq_train <- reddit_dtm_train[ , reddit_freq_terms]
reddit_dtm_freq_test <- reddit_dtm_test[ , reddit_freq_terms]

# Convert the counts into yes and no
convert_counts <- function(x) {
  x <- ifelse(x > 0, "Yes", "No")
}

reddit_train <- apply(reddit_dtm_freq_train, MARGIN = 2, convert_counts)
reddit_test  <- apply(reddit_dtm_freq_test, MARGIN = 2, convert_counts)

# Train the model on the data
reddit_classifier <- naiveBayes(reddit_train, reddit_train_labels, laplace = 1)

reddit_test_pred <- predict(reddit_classifier, reddit_test)

# Print the results
CrossTable(reddit_test_pred, reddit_test_labels, prop.chisq = FALSE, prop.t = FALSE, prop.r = FALSE, dnn = c('predicted', 'actual'))