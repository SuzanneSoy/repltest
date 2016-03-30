#lang racket

(provide (rename-out [repltest-read read]
                     [repltest-read-syntax read-syntax]
                     [repltest-get-info get-info]))

(require (for-template repltest/private/run-interactions)
         racket/syntax
         repltest/private/util
         (only-in syntax/module-reader make-meta-reader)
         syntax/strip-context)

(define ((wrap-reader reader) chr in src line col pos)
  (define/with-syntax (mod nm lang . body)
    (reader chr (narrow-until-prompt in) src line col pos))
  #`(module nm racket
      (module code lang . body)
      (require 'code)
      (provide (all-from-out 'code))
      (module test racket/base
        (require repltest/private/run-interactions)
        (run-interactions #'(mod nm lang . body)
                          (open-input-string #,(port->string in))
                          (#%variable-reference)))))

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
