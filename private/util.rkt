#lang racket/base

(provide read-pre-prompt
         read-actual-prompt
         skip-newline
         peek-read-length
         narrow-next-read
         peak-until-prompt-length
         narrow-until-prompt
         silent-prompt-read)

(require racket/syntax
         racket/port)

(define (read-pre-prompt in)
  (regexp-try-match #px"^\\s*" in))

(define (read-actual-prompt in)
  (regexp-try-match #px"^> " in))

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

;; Just like the default `current-prompt-read`, but without showing the prompt.
(define silent-prompt-read
  (λ ()
    (let ([in ((current-get-interaction-input-port))])
      ((current-read-interaction) (object-name in) in))))