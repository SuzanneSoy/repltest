REPLtest
========

This package provides the `#lang repltest` meta-language, which can be used to turn the transcript of an interactive racket session into a series of tests.

Usage:

```
raco pkg install repltest
```

Then write a file using the repltest meta-language, containing definitions at the top and interactions after the first prompt (by default the prompt is `"> "`, I will add customization options later).

```
#lang debug repltest typed/racket
;; There is a problem if there is a comment before a prompt, as comments aren't
;; gobbled-up by the preceeding read.
(define x 0)
(define y 1)
'displayed
(displayln "displayed too")

> (+ 1 1)
- : Integer [more precisely: Positive-Index]
2
> x
- : Integer [more precisely: Zero]
0
> (values x y)
- : (values Integer Integer) [more precisely: (Values Zero One)]
0
1
> #R(+ 2 0)
(+ 2 0) = 2
- : Integer [more precisely: Positive-Byte]
2
```