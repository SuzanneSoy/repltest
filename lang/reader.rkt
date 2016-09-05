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
  (define/with-syntax orig-mod
    (reader chr (narrow-until-prompt in) src line col pos))
  
  (define/with-syntax (mod nam lang (modbeg . body))
    (eval-syntax (syntax/loc #'orig-mod (expand #'orig-mod))
                   (variable-reference->namespace (#%variable-reference)))
    #;(parameterize ([current-namespace (variable-reference->namespace
                                       (#%variable-reference))])
      (expand #'orig-mod)))
  
  ;; quasisyntax/loc Necessary so that the generated code has the correct srcloc
  (quasisyntax/loc #'mod
    (mod nam lang
         (modbeg
          (module* test racket/base
            (require repltest/private/run-interactions)
            ;; TODO: set-port-next-location! for (open-input-string …)
            (run-interactions (open-input-string #,(port->string in))
                              (#%variable-reference)))
          . body))))

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
