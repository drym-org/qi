#lang scribble/doc
@require[scribble/manual
         scribble-abbrevs/manual
         scribble/example
         racket/sandbox
         pict/private/layout
         @for-label[syntax/on
                    racket]]

@(define eval-for-docs
  (parameterize ([sandbox-output 'string]
                 [sandbox-error-output 'string]
                 [sandbox-memory-limit #f])
                 (make-evaluator 'racket/base
                                 '(require syntax/on))))

@title{On - Predicate-based dispatch}
@author{Siddhartha Kasivajhula}

@defmodule[syntax/on]

Predicate-based dispatch.

This module provides a predicate-based dispatch form, @racket[on].

