using Levenshtein
using Base.Test

@test @show levenshtein("abcde","abcde") == 0
@test @show levenshtein("abcde","aabcde") == 1
@test @show levenshtein("abcd","abcde") == 1
@test @show levenshtein("abbcd","abcd") == 1
@test @show levenshtein("aecde","acde") == 1
@test @show levenshtein("abcdeff","abcde") == 2
@test @show levenshtein("existence","existent") == 2
@test @show levenshtein("eggistence","existances") == 4
