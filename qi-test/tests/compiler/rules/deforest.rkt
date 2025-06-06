#lang racket/base

(provide tests)

(require (for-syntax racket/base)
         "private/deforest-util.rkt"
         ;; necessary to recognize and expand core forms correctly
         qi/flow/extended/expander
         ;; necessary to correctly expand the right-threading form
         qi/flow/extended/forms
         qi/flow/core/compiler
         qi/flow/core/compiler/0100-deforest
         qi/list
         syntax/macro-testing
         (submod qi/flow/extended/expander invoke)
         rackunit
         rackunit/text-ui
         syntax/parse/define)

;; NOTE: we need to tag test syntax with `tag-form-syntax`
;; in some cases. See the comment on that function definition.

(define-syntax-parse-rule (test-deforested name stx)
  (test-true name
             (deforested?
               (phase1-eval
                (deforest-pass
                  (expand-flow stx))))))

(define-syntax-parse-rule (test-not-deforested name stx)
  (test-false name
              (deforested?
                (phase1-eval
                 (deforest-pass
                   (expand-flow stx))))))

(define-syntax-parse-rule (test-deforest stx)
  (phase1-eval
   (deforest-pass
     (expand-flow stx))))


(define tests

  (test-suite
   "deforestation"
   ;; Note that these test deforestation in isolation
   ;; *without* taking normalization (a preceding
   ;; step in compilation) into account.
   ;; If a test is failing that you are expecting should pass,
   ;; it could be that it implicitly assumes that normalization
   ;; will be done, so double check this.
   ;; For testing behavior of the full cycle of compilation
   ;; involving normalization as well as deforestation, use the
   ;; `full-cycle.rkt` test module.

   (test-suite
    "deforest-pass"

    (test-suite
     "general"
     (test-not-deforested "does not deforest single stream component in isolation"
                          #'(~> (filter odd?)))
     (test-deforested "deforests map in the head position"
                      #'(~> (map sqr) (filter odd?)))
     (test-deforested "deforestation is invariant to threading direction"
                      #'(~>> values
                             (filter odd?)
                             (map sqr)
                             values))
     (test-deforested "deforestation in arbitrary positions"
                      #'(~> values
                            (filter odd?)
                            (map sqr)
                            values))
     (test-deforested "deforestation in arbitrary positions"
                      #'(~> values
                            (filter string-upcase)
                            (foldl string-append "I")
                            values))
     ;; TODO: this test is for a case where deforestation should be applied twice
     ;; to the same expression. But currently, the test does not differentiate
     ;; between the optimization being applied once vs twice. We would like it
     ;; to do so in order to validate and justify the need for fixed-point
     ;; finding in the deforestation pass.
     (test-deforested "multiple applications of deforestation to the same expression"
                      #'(~> (filter odd?)
                            (map sqr)
                            (foldr + 0)
                            (as v)
                            (range v)
                            (filter odd?)
                            (map sqr)))
     (test-true "nested positions"
                (deforested? (phase1-eval
                              (deforest-pass
                                (expand-flow
                                 #'(>< (~> (filter odd?) (map sqr))))))))
     (test-case "multiple independent positions"
       (let ([stx (phase1-eval
                   (deforest-pass
                     (expand-flow
                      #'(-< (~> (filter odd?) (map sqr))
                            (~> (as v) (range v) car)))))])
         (check-true (deforested? stx))
         (check-true (filter-deforested? stx))
         (check-true (list-ref-deforested? stx)))))

    (test-suite
     "transformers"
     (test-deforested "filter->map (two transformers)"
                      #'(~> (filter odd?) (map sqr)))
     (test-suite
      "filter"
      (test-true "filter"
                 (filter-deforested?
                  (test-deforest
                   #'(~> (filter odd?) (map sqr))))))
     (test-suite
      "map"
      (test-true "map"
                 (map-deforested?
                  (test-deforest
                   #'(~> (filter odd?) (map sqr))))))
     (test-suite
      "filter-map"
      (test-true "filter-map"
                 (filter-map-deforested?
                  (test-deforest
                   #'(~> (filter odd?) (filter-map sqr))))))
     (test-suite
      "take"
      (test-true "take"
                 (take-deforested?
                  (test-deforest
                   #'(~> (filter odd?) (take 3)))))))

    (test-suite
     "producers"
     (test-suite
      "range"
      (test-true "range"
                 (range-deforested?
                  (test-deforest
                   #'(~> (range 10) (filter odd?)))))
      (test-true "range"
                 (range-deforested?
                  (test-deforest
                   #'(~> (range 1 10) (filter odd?)))))
      (test-true "range"
                 (range-deforested?
                  (test-deforest
                   #'(~> (range 1 10 2) (filter odd?)))))))

    (test-suite
     "consumers"
     (test-suite
      "list-ref"
      (test-deforested "car"
                       #'(~> (filter odd?) car))
      (test-true "car"
                 (list-ref-deforested?
                  (test-deforest
                   #'(~> (filter odd?) car))))
      (test-deforested "list-ref"
                       #'(~> (filter odd?) (list-ref 2)))
      (test-true "list-ref"
                 (list-ref-deforested?
                  (test-deforest
                   #'(~> (filter odd?) (list-ref 2))))))
     (test-suite
      "foldl"
      (test-deforested "foldl"
                       #'(~> (filter non-empty-string?) (foldl string-append "I")))
      (test-true "foldl"
                 (foldl-deforested?
                  (test-deforest
                   #'(~> (filter non-empty-string?) (foldl string-append "I"))))))
     (test-suite
      "foldr"
      (test-deforested "foldr"
                       #'(~> (filter non-empty-string?) (foldr string-append "I")))
      (test-true "foldr"
                 (foldr-deforested?
                  (test-deforest
                   #'(~> (filter non-empty-string?) (foldr string-append "I"))))))
     (test-suite
      "length"
      (test-deforested "length"
                       #'(~> (filter non-empty-string?) length))
      (test-true "length"
                 (length-deforested?
                  (test-deforest
                   #'(~> (filter non-empty-string?) length)))))
     (test-suite
      "empty?"
      (test-deforested "empty?"
                       #'(~> (filter non-empty-string?) empty?))
      (test-true "empty?"
                 (empty?-deforested?
                  (test-deforest
                   #'(~> (filter non-empty-string?) empty?))))
      (test-deforested "null?"
                       #'(~> (filter non-empty-string?) null?))
      (test-true "null?"
                 (empty?-deforested?
                  (test-deforest
                   #'(~> (filter non-empty-string?) null?)))))))))

(module+ main
  (void
   (run-tests tests)))
