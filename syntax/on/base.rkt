#lang racket/base

(require syntax/parse/define
         fancy-app
         racket/function
         (for-syntax racket/base))

(require "private/util.rkt")

(provide on-clause)

(begin-for-syntax
  (define (repeat n v)
    (if (= 0 n)
        null
        (cons v (repeat (sub1 n) v)))))

(define-syntax-parser conjux-clause
  [(_ (~datum _)) #'true.]
  [(_ onex:expr) #'(on-clause onex)])

(define-syntax-parser disjux-clause
  [(_ (~datum _)) #'false.]
  [(_ onex:expr) #'(on-clause onex)])

(define-syntax-parser on-clause
  [(_ ((~datum one-of?) v:expr ...)) #'(compose
                                        ->boolean
                                        (curryr member (list v ...)))]
  [(_ ((~datum all) onex:expr)) #'(give (curry andmap (on-clause onex)))]
  [(_ ((~datum any) onex:expr)) #'(give (curry ormap (on-clause onex)))]
  [(_ ((~datum none) onex:expr)) #'(on-clause (not (any onex)))]
  [(_ ((~datum and) onex:expr ...)) #'(conjoin (on-clause onex) ...)]
  [(_ ((~datum or) onex:expr ...)) #'(disjoin (on-clause onex) ...)]
  [(_ ((~datum not) onex:expr)) #'(negate (on-clause onex))]
  [(_ ((~datum and%) onex:expr ...)) #'(conjux (conjux-clause onex) ...)]
  [(_ ((~datum or%) onex:expr ...)) #'(disjux (disjux-clause onex) ...)]
  [(_ ((~datum with-key) f:expr onex:expr)) #'(compose
                                               (curry apply (on-clause onex))
                                               (give (curry map (on-clause f))))]
  [(_ ((~datum ..) onex:expr ...)) #'(compose (on-clause onex) ...)]
  [(_ ((~datum compose) onex:expr ...)) #'(compose (on-clause onex) ...)]
  [(_ ((~datum ~>) onex:expr ...)) #'(rcompose (on-clause onex) ...)]
  [(_ ((~datum thread) onex:expr ...)) #'(rcompose (on-clause onex) ...)]
  [(_ ((~datum ><) onex:expr)) #'(curry map-values (on-clause onex))]
  [(_ ((~datum amp) onex:expr)) #'(curry map-values (on-clause onex))]
  [(_ ((~datum ==) onex:expr ...)) #'(relay (on-clause onex) ...)]
  [(_ ((~datum relay) onex:expr ...)) #'(relay (on-clause onex) ...)]
  [(_ ((~datum -<) onex:expr ...)) #'(λ args (values (apply (on-clause onex) args) ...))]
  [(_ ((~datum tee) onex:expr ...)) #'(λ args (values (apply (on-clause onex) args) ...))]
  [(_ ((~datum splitter) n:number))
   (datum->syntax this-syntax
                  (cons 'on-clause
                        (list (cons '-<
                                    (repeat (syntax->datum #'n)
                                            #'identity)))))]
  ;; "prarg" = "pre-supplied argument"
  [(_ (onex prarg-pre ... (~datum _) prarg-post ...))
   #'((on-clause onex) prarg-pre ... _ prarg-post ...)]
  [(_ (onex prarg ...))
   #'(curryr (on-clause onex) prarg ...)]
  [(_ onex:expr) #'onex])
