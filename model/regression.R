library(rpart)
library(rpart.plot)
# library(RWeka)

options(warn = -1)

# Set seeds so any random input is reproducible
set.seed(123)

# Load our data
data <- read.csv("data/week6.csv", stringsAsFactors = FALSE)

# Filter out the attributes we care about
# data <- data[c("gilded", "title", "subreddit_name_prefixed", "domain", "score", "post_hint", "pinned", "locked", "num_crossposts", "num_comments")]
data <- data[c("gilded", "score", "post_hint", "pinned", "locked", "num_crossposts", "num_comments")]

# Convert factorable items into factors
# data$subreddit_name_prefixed <- as.factor(data$subreddit_name_prefixed)
# data$domain <- as.factor(data$domain)
data$post_hint <- as.factor(data$post_hint)
data$pinned <- as.factor(data$pinned)
data$locked <- as.factor(data$locked)
data$num_comments <- as.integer(data$num_comments)
data$num_crossposts <- as.integer(data$num_crossposts)

# Create a histogram of our scores
png("raw/regression_score_histogram.png")
hist(data$score, xlim = c(0, 80000), ylim = c(0, 1200), main = "Histogram of Scores", xlab = "Submission Score")
dev.off()

# Establish our training/testing datasets
train_size <- floor(0.8 * nrow(data))
train_ind <- sample(seq_len(nrow(data)), size = train_size)
data_train <- data[train_ind, ]
data_test <- data[-train_ind, ]

m.rpart <- rpart(score ~ ., data = data_train)
png("raw/regression_ruleset.png", width = 5, height = 4, units = "in", res = 300)
rpart.plot(m.rpart, fallen.leaves = TRUE, type = 3, digits = 2, extra = 101)
dev.off()

p.rpart <- predict(m.rpart, data_test)

cat("Summary of predicted\n")
print(summary(p.rpart))
cat("Summary of actual\n")
print(summary(data_test$score))

MAE <- function(actual, predicted) {
  mean(abs(actual - predicted))
}


cat(sprintf("Mean absolute error of predicted: %f\n", MAE(p.rpart, data_test$score)))
cat(sprintf("Mean absolute error of median: %f\n", MAE(mean(data_train$score), data_test$score)))

# m.m5p <- M5P(score ~ ., data = data_train)
# p.m5p <- predict(m.m5p, data_test)

# cat(sprintf("Mean absolute error of improved prediction: %f\n", MAE(data_test$score, p.m5p)))