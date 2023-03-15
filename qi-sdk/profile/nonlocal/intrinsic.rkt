#!/usr/bin/env racket
#lang racket/base

(provide benchmark)

(require "../util.rkt"
         "spec.rkt")

(define (benchmark language benchmarks-to-run)
  (let ([namespace (make-base-namespace)]
        [benchmarks-to-run (if (null? benchmarks-to-run)
                               (map bm-name specs)
                               benchmarks-to-run)])
    (cond [(equal? "qi" language) (eval '(require "qi/main.rkt") namespace)]
          [(equal? "racket" language) (eval '(require "racket/main.rkt") namespace)])

    (for/list ([spec specs]
               #:when (member (bm-name spec) benchmarks-to-run))
      (let ([name (bm-name spec)]
            [exerciser (bm-exerciser spec)]
            [f (eval (read (open-input-string (bm-name spec))) namespace)]
            [n-times (bm-times spec)])
        (run-nonlocal-benchmark name exerciser f n-times)))))
