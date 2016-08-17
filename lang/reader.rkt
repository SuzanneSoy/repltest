#lang racket

(provide (rename-out [repltest-read read]
                     [repltest-read-syntax read-syntax]
                     [repltest-get-info get-info]))

(require (for-template repltest/private/run-interactions)
         racket/syntax
         repltest/private/util
         (only-in syntax/module-reader make-meta-reader)
         syntax/strip-context)

;; Replaces the syntax/loc for the top of the syntax object, until
;; a part which doesn't belong to old-source is reached.
;; e.g. (with-syntax ([d user-provided-syntax])
;;        (replace-top-loc
;;          #'(a b (c d e))
;;          (syntax-source #'here)
;;          new-loc))
;; will produce a syntax object #'(a b (c (x (y) z) e))
;; where a, b, c, z, e and their surrounding forms have their srcloc set to
;; new-loc, but (x (y) z) will be left intact, if the user-provided-syntax
;; appears in another file.
(define (replace-top-loc stx old-source new-loc)
  (let process ([stx stx])
    (cond
      [(syntax? stx)
       (if (equal? (syntax-source stx) old-source)
           (datum->syntax stx (process (syntax-e stx)) new-loc stx)
           stx
           ;; Use the following expression to replace the loc throughout stx
           ;; instead of stopping the depth-first-search when the syntax-source
           ;; is not old-source anymore
           #;(datum->syntax stx (process (syntax-e stx)) stx stx))]
      [(pair? stx)
       (cons (process (car stx))
             (process (cdr stx)))]
      [(vector? stx)
       (list->vector (process (vector->list stx)))]
      [(prefab-struct-key stx)
       => (λ (key)
            (make-prefab-struct key
                                (process (struct->vector stx))))]
      [else
       stx])))

(define ((wrap-reader reader) chr in src line col pos)
  (define/with-syntax orig-mod
    (reader chr (narrow-until-prompt in) src line col pos))
  
  (define/with-syntax (mod nam lang (modbeg . body))
    #;(eval-syntax (replace-top-loc #'(expand #'orig-mod)
                                    (syntax-source #'here)
                                    #'orig-mod)
                   (variable-reference->namespace (#%variable-reference)))
    (parameterize ([current-namespace (variable-reference->namespace
                                       (#%variable-reference))])
      (expand #'orig-mod)))
  
  ;; quasisyntax/loc Necessary so that the generated code has the correct srcloc
  (replace-top-loc
   #`(mod nam lang
          (modbeg
           (module* test racket/base
             (require repltest/private/run-interactions)
             ;; TODO: set-port-next-location! for (open-input-string …)
             (run-interactions (open-input-string #,(port->string in))
                               (#%variable-reference)))
           . body))
   (syntax-source #'here)
   #'mod))

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
