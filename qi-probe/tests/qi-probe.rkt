#lang racket

(require rackunit
         rackunit/text-ui
         qi
         qi/probe)

(define-probed-flow my-flow0
  (~> sqr (* 3) add1))

(define-probed-flow my-flow1
  (~> readout sqr (* 3) add1))

(define-probed-flow my-flow2
  (~> sqr readout (* 3) add1))

(define-probed-flow my-flow3
  (~> sqr (* 3) readout add1))

(define-probed-flow my-flow4
  (~> sqr (* 3) add1 readout))

(define-flow my-flow1-B
  (~> readout sqr (* 3) add1))

(define-flow my-flow2-B
  (~> sqr readout (* 3) add1))

(define-flow my-flow3-B
  (~> sqr (* 3) readout add1))

(define-flow my-flow4-B
  (~> sqr (* 3) add1 readout))

(define tests
  (test-suite
   "qi-probe tests"
   (test-suite
    "inline invocation tests"
    (check-equal? (probe (~> (5) sqr (* 3) add1))
                  76
                  "no readout is equivalent to original")
    (check-equal? (probe (~> (5) readout sqr (* 3) add1))
                  5)
    (check-equal? (probe (~> (5) sqr readout (* 3) add1))
                  25)
    (check-equal? (probe (~> (5) sqr (* 3) readout add1))
                  75)
    (check-equal? (probe (~> (5) sqr (* 3) add1 readout))
                  76))
   (test-suite
    "separate definition and invocation tests"
    (check-equal? (probe (my-flow0 5))
                  76
                  "no readout is equivalent to original")
    (check-equal? (probe (my-flow1 5))
                  5)
    (check-equal? (probe (my-flow2 5))
                  25)
    (check-equal? (probe (my-flow3 5))
                  75)
    (check-equal? (probe (my-flow4 5))
                  76))
   (test-suite
    "separate definition and invocation tests using qi probe macro"
    (check-equal? (probe (my-flow1-B 5))
                  5)
    (check-equal? (probe (my-flow2-B 5))
                  25)
    (check-equal? (probe (my-flow3-B 5))
                  75)
    (check-equal? (probe (my-flow4-B 5))
                  76))))

(module+ test
  (void
   (run-tests tests)))
