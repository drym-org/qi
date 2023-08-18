#lang racket/base

(provide specs
         (struct-out bm))

(require "../util.rkt")

(struct bm (name exerciser times)
  #:transparent)

(define specs
  ;; the first datum in the benchmark name needs to be the name
  ;; of the function that will be exercised
  (list (bm "conditionals"
            check-value
            300000)
        (bm "composition"
            check-value
            300000)
        (bm "root-mean-square"
            check-list
            500000)
        (bm "filter-map"
            check-list
            500000)
        (bm "filter-map (large list)"
            check-large-list
            50000)
        (bm "range-map-sum"
            check-value-large
            5000)
        (bm "filter-map-values"
            check-values
            500000)
        (bm "double-list"
            check-list
            500000)
        (bm "double-values"
            check-values
            500000)
        (bm "factorial"
            check-value
            100000)
        (bm "pingala"
            check-value
            10000)
        (bm "eratosthenes"
            check-value-medium-large
            100)
        ;; See https://en.wikipedia.org/wiki/Collatz_conjecture
        (bm "collatz"
            check-value
            10000)))
