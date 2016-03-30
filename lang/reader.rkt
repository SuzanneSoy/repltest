#lang racket

(provide (rename-out [repltest-read read]
                     [repltest-read-syntax read-syntax]
                     [repltest-get-info get-info]))

(require syntax/module-reader
         racket/syntax
         rackunit)

(define (read-pre-prompt in)
  (regexp-try-match #px"^\\s*" in))

(define (read-actual-prompt in)
  (regexp-try-match #px"^> " in))

(define (peak-prompt in)
  (regexp-try-match #px"^\\s*> " (peeking-input-port in)))

(define (skip-newline in)
  (regexp-try-match #px"^\n" in))

(define (peek-read-length in)
  (let* ([pk (peeking-input-port in)]
         [start (file-position pk)]
         [r (read pk)]
         [end (file-position pk)])
    (- end start)))

(define (narrow-next-read in)
  (make-limited-input-port in (peek-read-length in)))

(define (peak-until-prompt-length in)
  (let* ([pk (peeking-input-port in)]
         [start (file-position pk)]
         [end (let loop ()
                (let* ([pre (read-pre-prompt pk)]
                       [pos (file-position pk)]
                       [pr (read-actual-prompt pk)])
                  (if (or pr (eof-object? (read pk)))
                      pos
                      (loop))))])
    (- end start)))

(define (narrow-until-prompt in)
  (make-limited-input-port in (peak-until-prompt-length in)))

(define silent-prompt-read
  (λ ()
    ;; Default current-prompt-read, without showing
    ;; the prompt
    (let ([in ((current-get-interaction-input-port))])
      ((current-read-interaction) (object-name in) in))))

(define (run-interactions mod-stx in-rest)
  (define/with-syntax (mod nm . body) mod-stx)
  (let ([ns (make-base-namespace)])
    (eval mod-stx ns)
    ;; This is a hack because I can't get (module->namespace ''m) to work:
    (define mod-ns (eval #'(begin (require racket/enter)
                                  (enter! 'nm #:dont-re-require-enter)
                                  (current-namespace))
                         ns))
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

(define ((wrap-reader reader) chr in src line col pos)
  (define/with-syntax (mod nm . body)
    (reader chr (narrow-until-prompt in) src line col pos))
  ;; Run interactions:
  (run-interactions #'(mod nm . body) in)
  #'(mod nm . body))

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
