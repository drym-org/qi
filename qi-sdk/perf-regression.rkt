#!/usr/bin/env racket
#lang cli

(require qi
         qi/probe)

(require relation
         json
         racket/format
         racket/port)

(define LOWER-THRESHOLD 0.75)
(define HIGHER-THRESHOLD 1.5)

(define (parse-json-file filename)
  (call-with-input-file filename
    (λ (port)
      (read-json port))))

(help
 (usage (~a "Reports relative performance of forms between two sets of results\n"
            "(e.g. run against two different commits).")))

(program (main [before-file "'before' file"] [after-file "'after' file"])
  (define before
    (make-hash
     (map (☯ (~> (-< (hash-ref 'name)
                     (hash-ref 'value)) cons))
          (parse-json-file before-file))))
  (define after
    (make-hash
     (map (☯ (~> (-< (~> (hash-ref 'name)
                         (switch
                           [(equal? "foldr") "<<"]
                           [(equal? "foldl") ">>"]
                           [else _]))
                     (hash-ref 'value)) cons))
          (parse-json-file after-file))))
  (define results
    (~>> (before)
         hash-keys
         △
         (><
          (~>
           (-< _
               (~> (-< (hash-ref after _)
                       (hash-ref before _))
                   /
                   (if (< LOWER-THRESHOLD _ HIGHER-THRESHOLD)
                       1
                       (~r #:precision 2))))
           ▽))
         ▽
         (sort > #:key (☯ (~> cadr ->inexact)))))
  ;; (write-json results)
  (println results))

(run main)
