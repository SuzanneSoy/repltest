#lang racket/base

(provide run-interactions
         run-interactions2)

(require racket/syntax
         racket/port
         rackunit
         repltest/private/util)

(define-syntax-rule (run-interactions in-rest varref)
  (begin
    (require (prefix-in "main-mod:" (submod "..")))
    (define res-mod
      (module-path-index-resolve
       (module-path-index-join '(submod "..")
                               (variable-reference->module-path-index varref))))
    (define mod-ns (module->namespace res-mod))
    (run-interactions2 in-rest mod-ns)))

(define (run-interactions2 in-rest mod-ns)
  (let loop ()
    (let* ([pr (read-actual-prompt in-rest)])
      (when pr
        (let* ([narrowed (narrow-next-read in-rest)]
               [os (open-output-string)]
               [actual (parameterize
                           ([current-prompt-read
                             silent-prompt-read]
                            [current-get-interaction-input-port
                             (λ () narrowed)]
                            [current-namespace mod-ns]
                            [current-output-port os]
                            [current-error-port os]
                            [current-print (λ (v)
                                             (unless (void? v)
                                               (print v)
                                               (newline)))])
                         (read-eval-print-loop)
                         (get-output-string os))]
               [skip (skip-newline in-rest)]
               [expected (port->string (narrow-until-prompt in-rest))])
          (check-equal? actual
                        expected))
        (loop)))))