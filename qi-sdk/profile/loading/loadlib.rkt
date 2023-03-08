#!/usr/bin/env racket
#lang racket/base

(provide profile-load)

(require pkg/require-latency
         racket/format)

(define (profile-load module-name)
  (let ([name (~a "(require " module-name ")")]
        [ms (cdr (time-module-ms module-name))])
    (displayln (~a name ": " ms " ms")
               (current-error-port))
    (hash 'name name
          'unit "ms"
          'value ms)))
