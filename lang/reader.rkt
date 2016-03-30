#lang racket

(provide (rename-out [repltest-read read]
                     [repltest-read-syntax read-syntax]
                     [repltest-get-info get-info]))

(require (for-template repltest/private/run-interactions)
         (for-template repltest/private/modbg)
         racket/syntax
         repltest/private/util
         (only-in syntax/module-reader make-meta-reader)
         syntax/strip-context)

(define ((wrap-reader reader) chr in src line col pos)
  (define/with-syntax (mod nm lang . body)
    (reader chr (narrow-until-prompt in) src line col pos))
  ;(displayln "WARNING: skipping tests")(port->string in) ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;DEBUG
  
  (with-syntax ([(m1 n1 l1 (mb1 . bd1))
                 (eval #'(expand #`(mod nm lang . body))
                       (variable-reference->namespace (#%variable-reference)))])
    #`(m1 n1 l1
          (mb1 (module* test racket/base
                 (require repltest/private/run-interactions)
                 (run-interactions ;#'(mod nm lang . body)
                  (open-input-string #,(port->string in))
                  (#%variable-reference)))
               . bd1)))
  
  ;#`(mod nm lang . body)
  #;#`(mod nm repltest/private/modbg
           require
           (module nm lang (require lang) . body)
           #;#,(port->string in)
           (module* test racket/base
             (require repltest/private/run-interactions)
             (run-interactions ;#'(mod nm lang . body)
              (open-input-string #,(port->string in))
              (#%variable-reference)))))
#|
      #;(insert-in-module
         (module code lang . body)
         (require 'code)
         (provide (all-from-out 'code))
         (module test racket/base
           (require repltest/private/run-interactions)
           (run-interactions #'(mod nm lang . body)
                             (open-input-string #,(port->string in))
                             (#%variable-reference))))
  
  #;(define/with-syntax (mod2 nm2 lang2 (modbeg2 . body2))
      (local-expand #'(module nm lang . body)
                    'module
                    '()))
  #;((λ (x)
       (displayln x)
       x)
     #`(mod2 nm2 lang2
             (modbeg2
              #;(module test racket/base
                  (require repltest/private/run-interactions)
                  (run-interactions #'(mod nm lang . body)
                                    (open-input-string #,(port->string in))
                                    (#%variable-reference)))
              . body2)))
  |#

(define-values (repltest-read repltest-read-syntax repltest-get-info)
  (make-meta-reader
   'repltest
   "language path"
   (lambda (bstr)
     (let* ([str (bytes->string/latin-1 bstr)]
            [sym (string->symbol str)])
       (and (module-path? sym)
            (vector
             ;; try submod first:
             `(submod ,sym reader)
             ;; fall back to /lang/reader:
             (string->symbol (string-append str "/lang/reader"))))))
   (λ (read) read)
   wrap-reader;wrap-read-syntax
   (lambda (proc)
     (lambda (key defval)
       (define (fallback) (if proc (proc key defval) defval))
       (case key
         [else (fallback)])))))
