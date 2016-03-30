#lang racket/base

(provide run-interactions)

(require racket/syntax
         racket/port
         rackunit
         repltest/private/util)

(define (run-interactions mod-stx in-rest varref)
  (define/with-syntax (mod nm lang . body) mod-stx)
  (let ([ns (make-base-namespace)])
    ;; This is a hack because I can't get (module->namespace ''nm) to work:
    (define res-mod
      (module-path-index-resolve
       (module-path-index-join '(submod ".." code)
                               (variable-reference->module-path-index varref))))
    (dynamic-require res-mod #f)
    (define mod-ns (module->namespace res-mod))
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
          (loop))))))