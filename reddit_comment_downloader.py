import json
import praw
import argparse
import csv
import pprint

def parse_args():
  parser = argparse.ArgumentParser()

  parser.add_argument("-s", "--subreddit", help = "The subreddit to grab comments from", required = True)
  parser.add_argument("-n", "--numposts", help = "The number of posts to grab comments from", type = int, required = True)
  parser.add_argument("-o", "--out", help = "The file to save results to", required = True)
  parser.add_argument("--sortby", help = "The method of sorting to use", choices = [
    "controversial",
    "gilded",
    "hot",
    "new",
    "rising",
    "top"
  ], default = "hot")
  parser.add_argument("--credentials", default="credentials.json", help = "Your user credentials")

  return parser.parse_args()

def get_maxscore_at_depth(comments, depth, maxes):
  if depth in maxes:
    return maxes[depth]
  best = -1000
  for comment in comments:
    if comment[3] == depth and comment[2] > best:
      best = comment[2]

  maxes[depth] = best
  return best

def get_comments(submission, subname, post):
  submission.comments.replace_more(limit=None)
  comments = []
  for comment in submission.comments.list():
    if hasattr(comment.author, "name") and hasattr(comment, "body"):
      comments.append([
        str(comment.author.name),
        str(comment.body),
        comment.score,
        comment.depth,
        subname,
        post
        ])
  return comments

def write_comments(writer, comments):
  maxes = {}
  for comment in comments:
    comment.append(get_maxscore_at_depth(comments, comment[3], maxes))
    writer.writerow(comment)

def download(args, reddit):
  subreddit = reddit.subreddit(args.subreddit)
  sortby = getattr(subreddit, args.sortby)

  with open(args.out, "w", encoding="utf-8", newline="") as outFile:
    writer = csv.writer(outFile, delimiter = ',', quotechar = '"', quoting = csv.QUOTE_NONNUMERIC)

    writer.writerow(["author", "body", "score", "depth", "subreddit", "permalink", "max_score_at_depth"])
    for submission in sortby(limit = args.numposts):
      comments = get_comments(submission, subreddit.display_name, submission.permalink)
      write_comments(writer, comments)


def init():
  args = parse_args()

  with open(args.credentials, "r") as credentialFile:
    credentialsJson = credentialFile.read()

  credentials = json.loads(credentialsJson)
  reddit = praw.Reddit(client_id = credentials["client_id"],
                       client_secret = credentials["client_secret"],
                       password = credentials["password"],
                       user_agent = credentials["user_agent"],
                       username = credentials["username"])

  download(args, reddit)

if __name__ == "__main__":
  init()