import csv

def get_word_freq(titles):
  word_count = {}
  word_total = 0
  for title in titles:
    words = title.split(" ")
    for word in words:
      word_total += 1
      if word in word_count:
        word_count[word] += 1
      else:
        word_count[word] = 0

  return {k:v for k,v in word_count.items() if (v/word_total) < 0.05}

def init():
  titles = []
  with open("../data/week8.csv", "r", encoding="utf-8", newline="") as week8:
    reader = csv.reader(week8, delimiter = ',', quotechar = '"')
    in_title_row = True
    for row in reader:
      if not in_title_row:
        titles.append(row[4])
      else:
        in_title_row = False

  removed_words = get_word_freq(titles)

  with open("../data/week8_filtered.csv", "w", encoding="utf-8", newline="") as filtered:
    for title in titles:
      words = title.split(" ")
      words = [a.replace('"',"").replace("'","") for a in words if a.lower() not in removed_words]

      if len(words) > 0:
        filtered.write(",".join(words) + "\n")

if __name__ == "__main__":
  init()