#lang racket/base

(provide specs
         (struct-out bm))

(require "../util.rkt")

(struct bm (name exerciser target times)
  #:transparent)

(define specs
  (list (bm "Conditionals"
            check-value
            "cond-fn"
            300000)
        (bm "Composition"
            check-value
            "compose-fn"
            300000)
        (bm "Root Mean Square"
            check-list
            "root-mean-square"
            500000)
        (bm "Filter-map"
            check-list
            "filter-map-fn"
            500000)
        (bm "Filter-map values"
            check-values
            "filter-map-values"
            500000)
        (bm "Double list"
            check-list
            "double-list"
            500000)
        (bm "Double values"
            check-values
            "double-values"
            500000)
        (bm "Factorial"
            check-value
            "fact"
            100000)
        (bm "Pingala"
            check-value
            "ping"
            10000)
        (bm "Eratosthenes"
            check-value-primes
            "eratos"
            100)
        ;; See https://en.wikipedia.org/wiki/Collatz_conjecture
        (bm "Collatz"
            check-value
            "collatz"
            10000)))
