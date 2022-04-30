#lang racket/base

(require (only-in data/collection
                  cycle
                  take
                  in)
         (only-in math sqr)
         racket/match
         qi
         racket/format)

(require "util.rkt")

(define (group . vs)
  (apply
   (☯ (~> (group 2 + _)
          (group 3 + _)
          (group 4 + _)
          +))
   vs))

(define (relay . vs)
  (apply
   (☯ (== add1
          sub1
          sqr
          add1
          sub1
          sqr
          add1
          sub1
          sqr
          add1))
   vs))

(define (amp . vs)
  (apply
   (☯ (>< sqr))
   vs))

(define (count . vs)
  (apply
   (☯ count)
   vs))

(define (ground . vs)
  (apply
   (☯ ⏚)
   vs))

(define (thread . vs)
  (apply
   (☯ (~> (+ 5)
          add1
          sub1
          sqr
          add1
          sub1
          sqr
          add1
          sub1
          sqr
          add1))
   vs))

(define (thread-right . vs)
  (apply
   (☯ (~>> (+ 5)
           add1
           sub1
           sqr
           add1
           sub1
           sqr
           add1
           sub1
           sqr
           add1))
   vs))

(define (crossover . vs)
  (apply
   (☯ X)
   vs))

(run-benchmark "group"
               check-values
               (local group)
               200000)

(run-benchmark "count"
               check-values
               (local count)
               1000000)

(run-benchmark "relay"
               check-values
               (local relay)
               50000)

(run-benchmark "amp"
               check-values
               (local amp)
               300000)

(run-benchmark "ground"
               check-values
               (local ground)
               200000)

(run-benchmark "thread"
               check-values
               (local thread)
               200000)

(run-benchmark "thread-right"
               check-values
               (local thread-right)
               200000)

(run-benchmark "crossover"
               check-values
               (local crossover)
               200000)
