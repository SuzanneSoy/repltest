#lang racket/base

(provide (rename-out [insert-in-module #%module-begin]))

(require (for-syntax racket/base
                     syntax/strip-context))

(define-syntax (insert-in-module stx)
  (syntax-case stx ()
    [(_ rr
        (mod1 nm1 lang1 (req lng) . bdy1);orig-mod
        submod
        ;str
        )
     (with-syntax ([(mod nm lang (modbg . body)) (expand ;#'orig-mod
                                                  #'(mod1 nm1 lang1 . bdy1))])
       ;(with-syntax ([req (datum->syntax #'md1 'require)])
       
       
       ((λ (x)
          (displayln x)
          x)
        (syntax-local-introduce
         #`(modbg ;(require lang)
            ;(req #,(datum->syntax #'req (syntax->datum #'lang)))
            ;(rr lang)
            . body)))
       
       #;#`(modbg ;(require lang)
            ;; ok for #%top-interaction:
            (req #,(datum->syntax #'req (syntax->datum #'lang)))
            ;; not ok for #%top-interaction:
            ;(req lang)
            (rr lang)
            (define varref (#,(datum->syntax #'lang '#%variable-reference)))
            (provide varref)
            submod
            #;(module* test racket/base
                (require repltest/private/run-interactions)
                (require (submod ".."))
                #;(define res-mod
                    (module-path-index-resolve
                     (module-path-index-join '(submod "..")
                                             (variable-reference->module-path-index
                                              varref))))
                ;(define mod-ns (module->namespace res-mod))
                (define mod-ns (variable-reference->namespace varref))
                (displayln mod-ns)
                (run-interactions2 (open-input-string str)
                                   mod-ns)
                #;(run-interactions (open-input-string str)
                                    #,(datum->syntax #'modbg '#%variable-reference)
                                    #;(#%variable-reference)))
            . body))]))