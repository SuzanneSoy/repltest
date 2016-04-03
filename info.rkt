#lang info
(define collection "repltest")
(define deps '("base"
               "rackunit-lib"
               "typed-racket-lib"
               "debug"))
(define build-deps '("scribble-lib" "racket-doc" "typed-racket-doc"))
(define scribblings '(("scribblings/repltest.scrbl" ())))
(define pkg-desc "Copy-paste your REPL interactions, and have them run as tests")
(define version "0.1")
(define pkg-authors '(|Georges Dupéron|))
