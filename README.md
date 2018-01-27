[![Build Status,](https://img.shields.io/travis/jsmaniac/repltest/master.svg)](https://travis-ci.org/jsmaniac/repltest)
[![Coverage Status,](https://img.shields.io/coveralls/jsmaniac/repltest/master.svg)](https://coveralls.io/github/jsmaniac/repltest)
[![Build Stats,](https://img.shields.io/badge/build-stats-blue.svg)](http://jsmaniac.github.io/travis-stats/#jsmaniac/repltest)
[![Online Documentation,](https://img.shields.io/badge/docs-online-blue.svg)](http://docs.racket-lang.org/repltest/)
[![Maintained as of 2018.](https://img.shields.io/maintenance/yes/2018.svg)](https://github.com/jsmaniac/repltest/issues)

REPLtest
========

This package provides the `#lang repltest` meta-language, which can be
used to turn the transcript of an interactive racket session into a
series of tests.

Installation
------------

Install this package with:

```
raco pkg install --deps search-auto repltest
```

Usage
-----

Write a file using the repltest meta-language, containing definitions at the
top and interactions after the first prompt (by default the prompt is `"> "`,
I will add customization options later). Each prompt is followed by a single
expression and by the expected result.

```
#lang debug repltest typed/racket
;; There is a problem if there is a comment before a prompt, as comments
;; are not gobbled-up by the preceding read. This will be fixed in a
;; later version.
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

When the `test` submodule of this file is executed (e.g. with `raco
test file.rkt`), `repltest` runs the expression after each `> `
prompt, and checks the expected result is produced.
