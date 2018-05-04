import json
import praw
import csv
import pprint
from progressbar import ProgressBar

DOWNLOADED_TITLES = 3000

def download(reddit, writer):
  progress = ProgressBar(max_value = DOWNLOADED_TITLES).start()
  headers = []
  current = 1
  for submission in reddit.subreddit("all").hot(limit = DOWNLOADED_TITLES):
    s_vars = vars(submission)
    if not headers:
      for key in s_vars:
        if type(s_vars[key]) in [str, int, bool]:
          headers.append(key)
      writer.writerow(headers)

    progress.update(current)
    current += 1

    if s_vars["over_18"]:
      continue
    row = []
    for key in headers:
      if key in s_vars:
        row.append(s_vars[key])

    writer.writerow(row)

def init():
  with open("credentials.json", "r") as credentialFile:
    credentialsJson = credentialFile.read()

  credentials = json.loads(credentialsJson)
  reddit = praw.Reddit(client_id = credentials["client_id"],
                       client_secret = credentials["client_secret"],
                       password = credentials["password"],
                       user_agent = credentials["user_agent"],
                       username = credentials["username"])
  with open("../data/week7.csv", "w", encoding="utf-8", newline="") as outFile:
    writer = csv.writer(outFile, delimiter = ',', quotechar = '"', quoting = csv.QUOTE_NONNUMERIC)
    download(reddit, writer)


if __name__ == "__main__":
  init()