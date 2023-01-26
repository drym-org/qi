#!/usr/bin/env racket
#lang racket/base

(provide parse-json-file
         parse-benchmarks
         compute-regression)

(require qi
         relation
         json
         racket/format)

(define LOWER-THRESHOLD 0.75)
(define HIGHER-THRESHOLD 1.5)

(define (parse-json-file filename)
  (call-with-input-file filename
    (λ (port)
      (read-json port))))

(define (parse-benchmarks benchmarks)
  (make-hash
   (map (☯ (~> (-< (~> (hash-ref 'name)
                       (switch
                         [(equal? "foldr") "<<"] ; these were renamed at some point
                         [(equal? "foldl") ">>"] ; so rename them back to match them
                         [else _]))
                   (hash-ref 'value))
               cons))
        benchmarks)))

(define (compute-regression before after)

  (define-flow calculate-ratio
    (~> (-< (hash-ref after _)
            (hash-ref before _))
        /
        (if (< LOWER-THRESHOLD _ HIGHER-THRESHOLD)
            1
            (~r #:precision 2))))

  (define results
    (~>> (before)
         hash-keys
         △
         (><
          (~>
           (-< _
               calculate-ratio)
           ▽))
         ▽
         (sort > #:key (☯ (~> cadr ->inexact)))))

  results)
