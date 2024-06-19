#lang racket/base

(require (prefix-in r: racket/base)
         (prefix-in r: racket/list)
         syntax/parse/define
         (for-syntax racket/syntax
                     syntax/parse
                     racket/base))

(define-syntax-parser define-and-provide-deforestable-bindings
  ((_ ids ...)
   (with-syntax (((rids ...) (for/list ((s (attribute ids)))
                               (format-id s "r:~a" s))))
     #'(begin
         (define ids rids) ...
         (provide ids ...)))))

(define-and-provide-deforestable-bindings
  range
  
  filter
  map
  filter-map
  take

  foldr
  foldl
  car
  cadr
  caddr
  cadddr
  list-ref
  length
  empty?
  null?)
