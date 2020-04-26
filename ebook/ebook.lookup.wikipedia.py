#!/usr/bin/python3

"""
    search.py

    MediaWiki API Demos
    Demo of `Search` module: Search for a text or title

    MIT License
"""

import re, argparse
import requests

# pip3 install -U requests --user

"""
@see https://stackoverflow.com/questions/9662346/python-code-to-remove-html-tags-from-a-string
"""
def remove_html_tags(html):
    return re.sub('<.*?>', '', html)

parser = argparse.ArgumentParser(description='TODO')
parser.add_argument('--text',  '-text',  dest='text',   action='store', type=str, default=None,  help='TODO')
args = vars(parser.parse_args())

session = requests.Session()

URL = "https://en.wikipedia.org/w/api.php"

SEARCHPAGE = args['text']

PARAMS = {
    "action": "query",
    "format": "json",
    "list": "search|query",
    "srlimit": 10,
    "srinfo": "rewrittenquery",
    "srprop": "redirecttitle|snippet|titlesnippet|redirectsnippet|sectiontitle|sectionsnippet|categorysnippet",
    "srsearch": SEARCHPAGE,
}

request = session.get(url=URL, params=PARAMS)
response = request.json()

authorsList = []
for match in response['query']['search']:
    textSnippet = remove_html_tags(match['snippet'])
    match['snippet_text'] = textSnippet

    if re.match(r'.*\W(author|writer|screenwriter)\W.*', match['snippet_text']):
        authorsList.append(match)


# searchTextList = re.split(r'\W+', args['text'])
# searchRegexp = []
# for r in searchTextList:
#     if len(r)>1:
#         searchRegexp.append("(%s)[a-z]{0,2}" % ("|".join(searchTextList)))

searchTextList = re.split(r'\s+', args['text'])
searchTextListExpanded = []
for t in searchTextList:
    if re.match(".+\.$", t):
        t = '%s[\w]+' % (t[:-1])
    searchTextListExpanded.append(t)

searchRegexp = []
for r in searchTextListExpanded:
    searchRegexp.append("(%s)[a-z]{0,2}" % ("|".join(searchTextListExpanded)))

possibleNames = []
for match in authorsList:
    #regexp = "(%s)" % ('[^,;\(\)\[\]\/]+'.join(searchRegexp))
    regexp = "(%s)" % ('\W+'.join(searchRegexp))
    names = re.findall(regexp, match['snippet_text'], re.IGNORECASE)
    for n in names:
        possibleNames.append(n[0])

if len(possibleNames):
    print("Name: %s" % possibleNames[0])
    exit(0)
else:
    print("Text not found")
    exit(1)
