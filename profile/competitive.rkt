#lang racket/base

(require (only-in data/collection
                  cycle
                  take
                  in)
         (only-in racket/list
                  range)
         (only-in racket/function
                  curryr)
         (prefix-in q: "qi.rkt")
         (prefix-in b: "builtin.rkt"))

(require "util.rkt")

(displayln "\nRunning flat benchmarks...")

(run-competitive-benchmark "Conditionals"
                           check-value
                           cond-fn
                           300000)

(run-competitive-benchmark "Composition"
                           check-value
                           compose-fn
                           300000)

(run-competitive-benchmark "Root Mean Square"
                           check-list
                           root-mean-square
                           500000)

(run-competitive-benchmark "Filter-map"
                           check-list
                           filter-map-fn
                           500000)

(run-competitive-benchmark "Filter-map values"
                           check-values
                           filter-map-values
                           500000)

(run-competitive-benchmark "Double list"
                           check-list
                           double-list
                           500000)

(run-competitive-benchmark "Double values"
                           check-values
                           double-values
                           500000)

(displayln "\nRunning Recursive benchmarks...")

(run-competitive-benchmark "Factorial"
                           check-value
                           fact
                           100000)

(run-competitive-benchmark "Pingala"
                           check-value
                           ping
                           10000)

(define check-value-primes (curryr check-value (list 100 200 300)))

(run-competitive-benchmark "Eratosthenes"
                           check-value-primes
                           eratos
                           100)

;; See https://en.wikipedia.org/wiki/Collatz_conjecture
(run-competitive-benchmark "Collatz"
                           check-value
                           collatz
                           10000)
