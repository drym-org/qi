#lang scribble/doc
@require[scribble/manual
         scribble-abbrevs/manual
         scribble/example
         racket/sandbox
         @for-label[qi
                    racket
                    (only-in relation
                             ->number
                             ->string
                             sum)]]

@(define eval-for-docs
  (parameterize ([sandbox-output 'string]
                 [sandbox-error-output 'string]
                 [sandbox-memory-limit #f])
    (make-evaluator 'racket/base
                    '(require qi
                              (only-in racket/list range)
                              racket/string
                              relation)
                    '(define (sqr x)
                       (* x x)))))

@title{Qi: A Functional, Flow-Oriented DSL}
@author{Siddhartha Kasivajhula}

@defmodule[qi]

An embeddable, general-purpose language to allow convenient framing of programming logic in terms of functional @emph{flows}.

For an overview, continue to the @seclink["Introduction_and_Usage"]{Introduction}. For a thorough orientation, @hyperlink["https://www.youtube.com/watch?v=XkIoGmWkEpM"]{watch the original video} from RacketCon 2021.

@table-of-contents[]

@section{Using These Docs}

@secref["Introduction_and_Usage"] describes the language and how to optimize your editor of choice to effectively write Qi. Learn the language by going through the @secref["Tutorial"], and read @secref["When_Should_I_Use_Qi_"] for examples illustrating its use. The various interfaces and forms of the language are documented in @secref["Language_Interface"] and @secref["Qi_Forms"]. The @secref["Field_Guide"] contains practical advice.

@include-section["intro.scrbl"]
@include-section["tutorial.scrbl"]
@include-section["interface.scrbl"]
@include-section["forms.scrbl"]
@include-section["using-qi.scrbl"]
@include-section["field-guide.scrbl"]
