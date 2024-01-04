#!/usr/bin/env racket
#lang racket/base

(provide require-latency)

(require pkg/require-latency
         racket/format)

(define (require-latency module-name)
  (let ([name (~a "(require " module-name ")")]
        [ms (cdr (time-module-ms module-name))])
    (displayln (~a name ": " ms " ms")
               (current-error-port))
    (hash 'name name
          'unit "ms"
          'value ms)))
