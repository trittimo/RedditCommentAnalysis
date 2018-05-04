library(arules)

# Load our data
data <- read.transactions("data/week8_filtered.csv", sep = ",")

png("raw/top_words_freqency_plot.png")
itemFrequencyPlot(data, topN = 20)
dev.off()

rules <- apriori(data = data, parameter = list(support = 0.0013, confidence = 0.8, minlen = 2))
inspect(rules[1:10])