#lang racket/base

(require racket/function
         racket/match)

(provide conjux
         disjux)

;; "juxtaposed conjoin"
(define (conjux . preds)
  (λ args
    (match* (preds args)
      [('() '()) #t]
      [((cons p ps) (cons v vs))
       (and (p v)
            (apply (apply conjux ps)
                   vs))]
      [(_ _) (apply raise-arity-error
                    'conjux
                    (length preds)
                    args)])))

;; "juxtaposed disjoin"
(define (disjux . preds)
  (λ args
    (match* (preds args)
      [('() '()) #f]
      [((cons p ps) (cons v vs))
       (or (p v)
           (apply (apply disjux ps)
                  vs))]
      [(_ _) (apply raise-arity-error
                    'disjux
                    (length preds)
                    args)])))
