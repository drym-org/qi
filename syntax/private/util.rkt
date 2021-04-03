#lang racket/base

(require racket/match)

(provide give
         conjux
         disjux)

;; give a (list-)lifted function available arguments
;; directly instead of wrapping them with a list
;; related to `unpack`
(define (give f)
  (λ args
    (f args)))

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
