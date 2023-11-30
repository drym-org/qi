#!/usr/bin/env racket
#lang racket/base

(provide parse-json-file
         parse-benchmarks
         compute-regression)

(require qi
         relation
         json
         racket/format
         racket/pretty)

(define LOWER-THRESHOLD 0.75)
(define HIGHER-THRESHOLD 1.33)

(define (parse-json-file filename)
  (call-with-input-file filename
    (λ (port)
      (read-json port))))

(define (parse-benchmarks benchmarks)
  ;; renames some forms so they're consistently named
  ;; but otherwise leaves the original data unmodified
  (make-hash
   (map (☯ (~> (-< (~> (hash-ref 'name)
                       (switch
                         [(equal? "foldr") "<<"] ; these were renamed at some point
                         [(equal? "foldl") ">>"] ; so rename them back to match them
                         [else _]))
                   (hash-ref 'value))
               cons))
        benchmarks)))

(define (compute-regression before
                            after
                            [low LOWER-THRESHOLD]
                            [high HIGHER-THRESHOLD])

  (define-flow calculate-ratio
    (~> (-< (hash-ref after _)
            (~> (hash-ref before _)
                ;; avoid division by zero
                (if (= 0) 1 _)))
        /
        (if (< low _ high)
            1
            (~r #:precision 2))))

  (define-flow reformat
    (~> △
        (>< (~> (-< car cadr)
                (hash 'name _ 'value _ 'unit "x")))
        ▽))

  (define (show-results results)
    (displayln "\nPerformance relative to baseline:" (current-error-port))
    (pretty-display results (current-error-port)))

  (define results
    (~>> (after)
         hash-keys
         △
         (><
          (~>
           (-< _
               calculate-ratio)
           ▽))
         ▽
         (sort > #:key (☯ (~> cadr ->inexact)))
         (ε show-results)
         reformat))

  results)
