#!/usr/bin/env racket
#lang cli

(provide benchmark)

(require "../util.rkt"
         "spec.rkt")

(define (benchmark language)
  (define namespace (make-base-namespace))
  (cond [(eq? 'qi language) (eval '(require "qi/main.rkt") namespace)]
        [(eq? 'racket language) (eval '(require "racket/main.rkt") namespace)])

  (for/list ([spec specs])
    (let ([name (bm-name spec)]
          [exerciser (bm-exerciser spec)]
          [f (eval (read (open-input-string (bm-target spec))) namespace)]
          [n-times (bm-times spec)])
      (run-nonlocal-benchmark name exerciser f n-times))))
