#!/usr/bin/python3

"""
    search.py

    MediaWiki API Demos
    Demo of `Search` module: Search for a text or title

    MIT License
"""

import re
import requests

# pip3 install -U requests --user

"""
@see https://stackoverflow.com/questions/9662346/python-code-to-remove-html-tags-from-a-string
"""
def remove_html_tags(html):
    return re.sub('<.*?>', '', html)

session = requests.Session()

URL = "https://en.wikipedia.org/w/api.php"

SEARCHPAGE = "A. E. Van Vogt"

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

print(response)
exit()


authorsList = []
for match in response['query']['search']:
    textSnippet = remove_html_tags(match['snippet'])
    match['snippet_text'] = textSnippet
    if re.match(".*\W(author|writer|screenwriter)\W.*", match['snippet_text']):
        authorsList.append(match)
print(authorsList)




# if DATA['query']['search'][0]['title'] == response:
#     print("Your search page '" + response + "' exists on English Wikipedia")