#lang afl repltest typed/racket

;; There is a problem if there is a comment before a prompt, as comments aren't
;; gobbled-up by the preceeding read.
(define x 0)
(define y #λ(list 3 %))
(define-syntax (module->namespace stx) #'error)
(provide module->namespace)
'displayed
(displayln "displayed too")

> (+ 1 1)
- : Integer [more precisely: Positive-Index]
2
> x
- : Integer [more precisely: Zero]
0
> (values x (y 2))
- : (values Integer (Listof Any)) [more precisely: (Values Zero (List Positive-Byte Any))]
0
'(3 2)
> (+ 2 0)
- : Integer [more precisely: Positive-Byte]
2
> (map add1 '(1 2 3 4))
- : (Listof Positive-Index) [more precisely: (Pairof Positive-Index (Listof Positive-Index))]
'(2 3 4 5)
