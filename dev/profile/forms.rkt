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

(run-benchmark "group"
               check-values
               (local group)
               200000)

(run-benchmark "relay"
               check-values
               (local relay)
               50000)

(run-benchmark "amp"
               check-values
               (local amp)
               300000)
