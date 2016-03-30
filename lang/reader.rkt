#lang racket

(provide (rename-out [repltest-read read]
                     [repltest-read-syntax read-syntax]
                     [repltest-get-info get-info]))

(require syntax/module-reader)

#;(define (repltest-read in)
    (syntax->datum
     (repltest-read-syntax #f in)))

(define (read-prompt in)
  (regexp-try-match #px"^\\s*[0-9]> " in))

(define (read-user-input reader args)
  (apply reader args))

(define (read-output-values reader args in)
  (if (read-prompt in)
      '()
      (let ([rs (apply reader args)])
        (if (eof-object? rs)
            '()
            (read-output-values reader args in)))))

#;(let ([is (open-input-string "(+ 1 1) 'aaa")]
        [os (open-output-string)])
    (parameterize ([current-get-interaction-input-port
                    (λ () is)]
                   [current-namespace (make-base-namespace)]
                   [current-output-port os]
                   [current-error-port os]
                   [current-print (λ (v)
                                    (unless (void? v)
                                      (print v)
                                      (newline)))])
      (read-eval-print-loop))
    
    (display (get-output-string os)))



#;(define-values (wrap-read wrap-read-syntax)
    (let ()
      (define (wrap default-reader reader src in . args)
        ;(displayln (apply default-reader args))
        ;((λ (x) (displayln x) x) (apply reader args))
        (displayln args)
        ((λ (x) (displayln x) x)
         (apply reader src in (cddr args)));;TODO: not cddr for read
        #;#`(module m typed/racket
              '#,(default-reader src in))
        #;(let* ([in (if (null? (cdr args)) (car args) (cadr args))]
                 [maybe-prompt (read-prompt in)])
            (if maybe-prompt
                ((λ (x) (displayln x) x) (apply reader args))
                ((λ (x) (displayln x) x) (apply reader args))))
        #;(let* ([in (if (null? (cdr args)) (car args) (cadr args))]
                 [first-prompt (read-prompt in)]
                 [user-input (read-user-input reader args)]
                 [output-values (read-output-values reader args in)])
            (if first-prompt
                #`(module anything racket
                    '(check-equal? #,user-input
                                   (values . #,output-values))
                    (let ([os (open-output-string)])
                      (parameterize ([current-input-port (open-input-string "")]
                                     [current-output-port os])
                        'todo
                        (get-output-string os))))
                #'(module anything racket #f))))
      (values (λ (reader)
                (λ args
                  (apply wrap read reader #f (car args) args)))
              (λ (reader)
                (λ args
                  (apply wrap
                         read-syntax
                         reader
                         (car args)
                         (cadr args)
                         args))))))

(define (read-one-interaction src in)
  (let ([prompt (read-prompt in)])
    (if (not prompt)
        (values eof #f '())
        (let ([user-input (read-syntax src in)]
              [output-values (let loop ()
                               (if (read-prompt (peeking-input-port in))
                                   '()
                                   (let ([val (read-syntax src in)])
                                     (if (eof-object? val)
                                         '()
                                         (cons val (loop))))))])
          (if (eof-object? user-input)
              (values (car prompt) #f '())
              (values (car prompt) user-input output-values))))))

(define ((wrap-reader reader) chr in src line col pos)
  (let* ([pk (peeking-input-port in)]
         [start (file-position pk)]
         [end (let loop ()
                (let* ([pos (file-position pk)]
                       [pr (read-prompt pk)])
                  (if (or pr (eof-object? (read pk)))
                      pos
                      (loop))))])
    (with-syntax ([(mod nm . body)
                   (reader chr
                           (make-limited-input-port in (- end start))
                           src line col pos)])
      (let loop ()
        (let-values ([(p u o) (read-one-interaction src in)])
          (when u
            ;(display p)
            ;(displayln (syntax->datum u))
            ;(map displayln (map syntax->datum o))
            (loop))))
      ;; Run interactions:
      (let ([is (open-input-string "x y (number->string (+ 1 1))")]
            [os (open-output-string)]
            [ns (make-base-namespace)])
        (eval #'(mod nm . body) ns)
        ;; This is a hack because I can't get (module->namespace ''m) to work:
        (define mod-ns (eval #'(begin (require racket/enter)
                                      (enter! 'nm #:dont-re-require-enter)
                                      (current-namespace))
                             ns))
        (parameterize ([current-get-interaction-input-port
                        (λ () is)]
                       [current-namespace mod-ns]
                       [current-output-port os]
                       [current-error-port os]
                       [current-print (λ (v)
                                        (unless (void? v)
                                          (print v)
                                          (newline)))])
          (read-eval-print-loop))
        
        (display (get-output-string os)))
      #'(mod nm racket) #;#'(mod nm . body))))

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


#|
#lang racket
(let ([is (open-input-string "x y (number->string (+ 1 1))")]
      [os (open-output-string)]
      [ns (make-base-namespace)])
  (eval #'(module m typed/racket
            (define x 0)
            (define y 1)
            'displayed
            (displayln "aaaa"))
        ns)
  (define mod-ns (eval #'(begin (require racket/enter)
                                (enter! 'm #:dont-re-require-enter)
                                (current-namespace))
                       ns))
  (parameterize ([current-get-interaction-input-port
                  (λ () is)]
                 [current-namespace mod-ns]
                 [current-output-port os]
                 [current-error-port os]
                 [current-print (λ (v)
                                  (unless (void? v)
                                    (print v)
                                    (newline)))])
    (read-eval-print-loop))
  
  (display (get-output-string os)))
|#