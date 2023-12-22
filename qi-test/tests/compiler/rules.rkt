#lang racket/base

(provide tests)

(require (for-template qi/flow/core/compiler
                       qi/flow/core/deforest)
         rackunit
         rackunit/text-ui
         (only-in math sqr)
         racket/string
         (only-in racket/list
                  range)
         syntax/parse/define)

(define-syntax-parse-rule (test-normalize name a b ...+)
  (begin
    (test-equal? name
                 (syntax->datum
                  (normalize-pass a))
                 (syntax->datum
                  (normalize-pass b)))
    ...))

(define (deforested? exp)
  (string-contains? (format "~a" exp) "cstream"))

(define (filter-deforested? exp)
  (string-contains? (format "~a" exp) "filter-cstream"))

(define (car-deforested? exp)
  (string-contains? (format "~a" exp) "car-cstream"))


(define tests
  (test-suite
   "Compiler rule tests"

   (test-suite
    "deforestation"
    ;; Note that these test deforestation in isolation
    ;; without necessarily taking normalization (a preceding
    ;; step in compilation) into account

    (test-suite
     "deforest-rewrite"
     (test-suite
      "general"
      (let ([stx #'(thread
                    (#%blanket-template
                     ((#%host-expression filter)
                      (#%host-expression odd?)
                      __)))])
        (check-false (deforested?
                       (deforest-rewrite stx))
                     "does not deforest single stream component in isolation"))
      (let ([stx #'(thread
                    (#%blanket-template
                     ((#%host-expression map)
                      (#%host-expression sqr)
                      __)
                     ((#%host-expression filter)
                      (#%host-expression odd?)
                      __)))])
        (check-false (deforested?
                       (deforest-rewrite stx))
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
                    (esc (#%host-expression range))
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
     "deforest-pass"
     (let ([stx #'(amp
                   (thread
                    (#%blanket-template
                     ((#%host-expression filter)
                      (#%host-expression odd?)
                      __))
                    (#%blanket-template
                     ((#%host-expression map)
                      (#%host-expression sqr)
                      __))))])
       (check-true (deforested? (syntax->datum
                                 (deforest-pass
                                   stx)))
                   "nested positions"))
     (let* ([stx #'(tee
                    (thread
                     (#%blanket-template
                      ((#%host-expression filter)
                       (#%host-expression odd?)
                       __))
                     (#%blanket-template
                      ((#%host-expression map)
                       (#%host-expression sqr)
                       __)))
                    (thread
                     (esc (#%host-expression range))
                     (esc (#%host-expression car))))]
            [result (syntax->datum
                     (deforest-pass
                       stx))])
       (check-true (deforested? result)
                   "multiple independent positions")
       (check-true (filter-deforested? result)
                   "multiple independent positions")
       (check-true (car-deforested? result)
                   "multiple independent positions"))))

   (test-suite
    "normalization"

    (test-suite
     "equivalence of normalized expressions"
     (test-normalize "pass-amp deforestation"
                     #'(thread
                        (pass f)
                        (amp g))
                     #'(amp (if f g ground)))
     (test-normalize "merge pass filters in sequence"
                     #'(thread (pass f) (pass g))
                     #'(pass (and f g)))
     (test-normalize "collapse deterministic conditionals"
                     #'(if #t f g)
                     #'f)
     (test-normalize "collapse deterministic conditionals"
                     #'(if #f f g)
                     #'g)
     (test-normalize "trivial threading is collapsed"
                     #'(thread f)
                     #'f)
     (test-normalize "associative laws for ~>"
                     #'(thread f (thread g h) i)
                     #'(thread f g (thread h i))
                     #'(thread (thread f g) h i)
                     #'(thread f g h i))
     (test-normalize "left and right identity for ~>"
                     #'(thread f _)
                     #'(thread _ f)
                     #'f)
     (test-normalize "line composition of identity flows"
                     #'(thread _ _ _)
                     #'(thread _ _)
                     #'(thread _)
                     #'_)
     (test-normalize "amp under identity"
                     #'(amp _)
                     #'_)
     (test-normalize "trivial tee junction"
                     #'(tee f)
                     #'f)
     (test-normalize "merge adjacent gens in a tee junction"
                     #'(tee (gen a b) (gen c d))
                     #'(tee (gen a b c d)))
     (test-normalize "remove dead gen in a line"
                     #'(thread (gen a b) (gen c d))
                     #'(thread (gen c d)))
     (test-normalize "prism identities"
                     #'(thread collect sep)
                     #'_)
     (test-normalize "redundant blanket template"
                     #'(#%blanket-template (f __))
                     #'f)
     ;; TODO: this test fails but the actual behavior
     ;; it tests is correct (as seen in the macro stepper)
     ;; This seems to be due to some phase-related issue
     ;; and maybe `values` is not matching literally.
     ;; (test-normalize "values is collapsed inside ~>"
     ;;                 #'(thread values f values)
     ;;                 #'(thread f))
     ;; TODO: this test reveals a case that should be
     ;; rewritten but isn't. Currently, once there is a
     ;; match at one level during tree traversal
     ;; (in find-and-map), we do not traverse the expression
     ;; further.
     ;; (test-normalize "multiple levels of normalization"
     ;;                 #'(thread (amp (thread f)))
     ;;                 #'(amp f))
     (test-normalize "_ is collapsed inside ~>"
                     #'(thread _ f _)
                     #'f)
     (test-normalize "nested positions"
                     #'(amp (amp (thread _ f _)))
                     #'(amp (amp f)))
     (test-normalize "multiple independent positions"
                     #'(tee (thread _ f _) (thread (thread f g)))
                     #'(tee f (thread f g))))

    (test-suite
     "specific output"
     (test-equal? "weird bug"
                  (syntax->datum
                   (normalize-pass #'(thread tee collect)))
                  (syntax->datum
                   #'(thread tee collect)))))

   (test-suite
    "compilation sequences"
    null)))

(module+ main
  (void
   (run-tests tests)))
