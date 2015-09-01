#requires python and python-levenshtein
using PyCall

@pyimport Levenshtein as pyleven

res = pyleven.editops("tracker", "tracers")
