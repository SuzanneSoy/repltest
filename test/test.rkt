#lang debug repltest typed/racket
;; There is a problem if there is a comment before a prompt, as comments aren't
;; gobbled-up by the preceeding read.
(define x 0)
(define y 1)
'displayed
(displayln "displayed too")

1> (+ 1 1)
2
2> x
0

3> (values x y)
0
1
4> #R(+ 2 0)
(+ 2 0) = 2
2

#|
(values (+ 1 1) 4)
#R(+ 2 0)
4
|#