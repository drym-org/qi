#lang racket/base

(provide tests)

(require (for-template qi/flow/core/deforest
                       qi/flow/core/compiler)
         rackunit
         rackunit/text-ui
         (only-in math sqr)
         racket/string
         (only-in racket/function curryr))

(define-syntax-rule (test-normalize a b msg)
  (check-equal? (syntax->datum
                 (normalize-pass a))
                (syntax->datum
                 (normalize-pass b))
                msg))

(define (deforested? exp)
  (string-contains? (format "~a" exp) "cstream"))


(define tests
  (test-suite
   "compiler tests"

   (test-suite
    "fixed point"
    (check-equal? ((fix abs) -1) 1)
    (check-equal? ((fix abs) -1) 1)
    (let ([integer-div2 (compose floor (curryr / 2))])
      (check-equal? ((fix integer-div2) 10)
                    0)))
   (test-suite
    "deforestation"
    ;; Note that these test deforestation in isolation
    ;; without necessarily taking normalization (a preceding
    ;; step in compilation) into account

    (test-suite
     "general"
     (let ([stx #'(thread
                   (#%blanket-template
                    ((#%host-expression filter)
                     (#%host-expression odd?)
                     __)))])
       (check-false (deforested? (syntax->datum
                                  (deforest-rewrite
                                    stx)))
                    "does not deforest single stream component in isolation"))
     (let ([stx #'(thread
                   #%blanket-template
                   ((#%host-expression map)
                    (#%host-expression sqr)
                    __)
                   ((#%host-expression filter)
                    (#%host-expression odd?)
                    __))])
       (check-false (deforested? (syntax->datum
                                  (deforest-rewrite
                                    stx)))
                    "does not deforest map in the head position"))
     ;; (~>> values (filter odd?) (map sqr) values)
     (let ([stx #'(thread
                   values
                   (#%blanket-template
                    ((#%host-expression filter)
                     (#%host-expression odd?)
                     __))
                   (#%blanket-template
                    ((#%host-expression map)
                     (#%host-expression sqr)
                     __))
                   values)])
       (check-true (deforested? (syntax->datum
                                 (deforest-rewrite
                                   stx)))
                   "deforestation in arbitrary positions"))
     (let ([stx #'(thread
                   values
                   (#%blanket-template
                    ((#%host-expression filter)
                     (#%host-expression string-upcase)
                     __))
                   (#%blanket-template
                    ((#%host-expression foldl)
                     (#%host-expression string-append)
                     (#%host-expression "I")
                     __))
                   values)])
       (check-true (deforested? (syntax->datum
                                 (deforest-rewrite
                                   stx)))
                   "deforestation in arbitrary positions")))

    (test-suite
     "transformers"
     (let ([stx #'(thread
                   (#%blanket-template
                    ((#%host-expression filter)
                     (#%host-expression odd?)
                     __))
                   (#%blanket-template
                    ((#%host-expression map)
                     (#%host-expression sqr)
                     __)))])
       (check-true (deforested? (syntax->datum
                                 (deforest-rewrite
                                   stx)))
                   "filter"))
     (let ([stx #'(thread
                   (#%blanket-template
                    ((#%host-expression filter)
                     (#%host-expression odd?)
                     __))
                   (#%blanket-template
                    ((#%host-expression map)
                     (#%host-expression sqr)
                     __)))])
       (check-true (deforested? (syntax->datum
                                 (deforest-rewrite
                                   stx)))
                   "filter-map (two transformers)"))
     (let ([stx #'(thread
                   (#%fine-template
                    ((#%host-expression filter)
                     (#%host-expression odd?)
                     _))
                   (#%fine-template
                    ((#%host-expression map)
                     (#%host-expression sqr)
                     _)))])
       (check-true (deforested? (syntax->datum
                                 (deforest-rewrite
                                   stx)))
                   "fine-grained template forms")))

    (test-suite
     "producers"
     (let ([stx #'(thread
                   (#%host-expression range)
                   (#%blanket-template
                    ((#%host-expression filter)
                     (#%host-expression odd?)
                     __)))])
       (check-true (deforested? (syntax->datum
                                 (deforest-rewrite
                                   stx)))
                   "range"))
     (let ([stx #'(thread
                   (#%fine-template
                    ((#%host-expression range)
                     _))
                   (#%blanket-template
                    ((#%host-expression filter)
                     (#%host-expression odd?)
                     __)))])
       (check-true (deforested? (syntax->datum
                                 (deforest-rewrite
                                   stx)))
                   "(range _)"))
     (let ([stx #'(thread
                   (#%fine-template
                    ((#%host-expression range)
                     _
                     _))
                   (#%blanket-template
                    ((#%host-expression filter)
                     (#%host-expression odd?)
                     __)))])
       (check-true (deforested? (syntax->datum
                                 (deforest-rewrite
                                   stx)))
                   "(range _ _)"))
     (let ([stx #'(thread
                   (#%fine-template
                    ((#%host-expression range)
                     _
                     _))
                   (#%blanket-template
                    ((#%host-expression filter)
                     (#%host-expression odd?)
                     __)))])
       (check-true (deforested? (syntax->datum
                                 (deforest-rewrite
                                   stx)))
                   "(range 0 _)"))
     (let ([stx #'(thread
                   (#%fine-template
                    ((#%host-expression range)
                     _
                     _))
                   (#%blanket-template
                    ((#%host-expression filter)
                     (#%host-expression odd?)
                     __)))])
       (check-true (deforested? (syntax->datum
                                 (deforest-rewrite
                                   stx)))
                   "(range _ 10)"))
     (let ([stx #'(thread
                   (#%fine-template
                    ((#%host-expression range)
                     _
                     _))
                   (#%blanket-template
                    ((#%host-expression filter)
                     (#%host-expression odd?)
                     __)))])
       (check-true (deforested? (syntax->datum
                                 (deforest-rewrite
                                   stx)))
                   "(range _ _ _)"))
     (let ([stx #'(thread
                   (#%fine-template
                    ((#%host-expression range)
                     _
                     _))
                   (#%blanket-template
                    ((#%host-expression filter)
                     (#%host-expression odd?)
                     __)))])
       (check-true (deforested? (syntax->datum
                                 (deforest-rewrite
                                   stx)))
                   "(range _ _ 1)"))
     (let ([stx #'(thread
                   (#%fine-template
                    ((#%host-expression range)
                     _
                     _))
                   (#%blanket-template
                    ((#%host-expression filter)
                     (#%host-expression odd?)
                     __)))])
       (check-true (deforested? (syntax->datum
                                 (deforest-rewrite
                                   stx)))
                   "(range _ 10 _)"))
     (let ([stx #'(thread
                   (#%fine-template
                    ((#%host-expression range)
                     _
                     _))
                   (#%blanket-template
                    ((#%host-expression filter)
                     (#%host-expression odd?)
                     __)))])
       (check-true (deforested? (syntax->datum
                                 (deforest-rewrite
                                   stx)))
                   "(range _ 10 1)"))
     (let ([stx #'(thread
                   (#%fine-template
                    ((#%host-expression range)
                     _
                     _))
                   (#%blanket-template
                    ((#%host-expression filter)
                     (#%host-expression odd?)
                     __)))])
       (check-true (deforested? (syntax->datum
                                 (deforest-rewrite
                                   stx)))
                   "(range 0 _ _)"))
     (let ([stx #'(thread
                   (#%fine-template
                    ((#%host-expression range)
                     _
                     _))
                   (#%blanket-template
                    ((#%host-expression filter)
                     (#%host-expression odd?)
                     __)))])
       (check-true (deforested? (syntax->datum
                                 (deforest-rewrite
                                   stx)))
                   "(range 0 _ 1)"))
     (let ([stx #'(thread
                   (#%fine-template
                    ((#%host-expression range)
                     _
                     _))
                   (#%blanket-template
                    ((#%host-expression filter)
                     (#%host-expression odd?)
                     __)))])
       (check-true (deforested? (syntax->datum
                                 (deforest-rewrite
                                   stx)))
                   "(range 0 10 _)"))
     (let ([stx #'(thread
                   (#%fine-template
                    ((#%host-expression range)
                     _
                     _))
                   (#%blanket-template
                    ((#%host-expression filter)
                     (#%host-expression odd?)
                     __)))])
       (check-true (deforested? (syntax->datum
                                 (deforest-rewrite
                                   stx)))
                   "(range __)"))
     (let ([stx #'(thread
                   (#%fine-template
                    ((#%host-expression range)
                     _
                     _))
                   (#%blanket-template
                    ((#%host-expression filter)
                     (#%host-expression odd?)
                     __)))])
       (check-true (deforested? (syntax->datum
                                 (deforest-rewrite
                                   stx)))
                   "(range 0 __)"))
     (let ([stx #'(thread
                   (#%fine-template
                    ((#%host-expression range)
                     _
                     _))
                   (#%blanket-template
                    ((#%host-expression filter)
                     (#%host-expression odd?)
                     __)))])
       (check-true (deforested? (syntax->datum
                                 (deforest-rewrite
                                   stx)))
                   "(range __ 1)"))
     (let ([stx #'(thread
                   (#%fine-template
                    ((#%host-expression range)
                     _
                     _))
                   (#%blanket-template
                    ((#%host-expression filter)
                     (#%host-expression odd?)
                     __)))])
       (check-true (deforested? (syntax->datum
                                 (deforest-rewrite
                                   stx)))
                   "(range 0 10 __)"))
     (let ([stx #'(thread
                   (#%fine-template
                    ((#%host-expression range)
                     _
                     _))
                   (#%blanket-template
                    ((#%host-expression filter)
                     (#%host-expression odd?)
                     __)))])
       (check-true (deforested? (syntax->datum
                                 (deforest-rewrite
                                   stx)))
                   "(range __ 10 1)"))
     (let ([stx #'(thread
                   (#%fine-template
                    ((#%host-expression range)
                     _
                     _))
                   (#%blanket-template
                    ((#%host-expression filter)
                     (#%host-expression odd?)
                     __)))])
       (check-true (deforested? (syntax->datum
                                 (deforest-rewrite
                                   stx)))
                   "(range 0 __ 1)"))
     (let ([stx #'(thread
                   (#%fine-template
                    ((#%host-expression range)
                     _
                     _))
                   (#%blanket-template
                    ((#%host-expression filter)
                     (#%host-expression odd?)
                     __)))])
       (check-true (deforested? (syntax->datum
                                 (deforest-rewrite
                                   stx)))
                   "(range 0 10 1 __)"))
     (let ([stx #'(thread
                   (#%fine-template
                    ((#%host-expression range)
                     _
                     _))
                   (#%blanket-template
                    ((#%host-expression filter)
                     (#%host-expression odd?)
                     __)))])
       (check-true (deforested? (syntax->datum
                                 (deforest-rewrite
                                   stx)))
                   "(range 0 10 __ 1)"))
     (let ([stx #'(thread
                   (#%fine-template
                    ((#%host-expression range)
                     _
                     _))
                   (#%blanket-template
                    ((#%host-expression filter)
                     (#%host-expression odd?)
                     __)))])
       (check-true (deforested? (syntax->datum
                                 (deforest-rewrite
                                   stx)))
                   "(range 0 __ 10 1)"))
     (let ([stx #'(thread
                   (#%fine-template
                    ((#%host-expression range)
                     _
                     _))
                   (#%blanket-template
                    ((#%host-expression filter)
                     (#%host-expression odd?)
                     __)))])
       (check-true (deforested? (syntax->datum
                                 (deforest-rewrite
                                   stx)))
                   "(range __ 0 10 1)")))

    (test-suite
     "consumers"
     (let ([stx #'(thread
                   (#%blanket-template
                    ((#%host-expression filter)
                     (#%host-expression odd?)
                     __))
                   (esc (#%host-expression car)))])
       (check-true (deforested? (syntax->datum
                                 (deforest-rewrite
                                   stx)))
                   "car"))
     (let ([stx #'(thread
                   (#%blanket-template
                    ((#%host-expression filter)
                     (#%host-expression string-upcase)
                     __))
                   (#%blanket-template
                    ((#%host-expression foldl)
                     (#%host-expression string-append)
                     (#%host-expression "I")
                     __)))])
       (check-true (deforested? (syntax->datum
                                 (deforest-rewrite
                                   stx)))
                   "foldl"))
     (let ([stx #'(thread
                   (#%blanket-template
                    ((#%host-expression filter)
                     (#%host-expression string-upcase)
                     __))
                   (#%blanket-template
                    ((#%host-expression foldr)
                     (#%host-expression string-append)
                     (#%host-expression "I")
                     __)))])
       (check-true (deforested? (syntax->datum
                                 (deforest-rewrite
                                   stx)))
                   "foldr"))))

   (test-suite
    "normalization"
    (test-normalize #'(thread
                       (thread (filter odd?)
                               (map sqr)))
                    #'(thread (filter odd?)
                              (map sqr))
                    "nested threads are collapsed")
    (test-normalize #'(thread values
                              sqr)
                    #'(thread sqr)
                    "values inside threading is elided")
    (test-normalize #'(thread sqr)
                    #'sqr
                    "trivial threading is collapsed"))

   (test-suite
    "compilation sequences"
    null)))

(module+ main
  (void (run-tests tests)))
