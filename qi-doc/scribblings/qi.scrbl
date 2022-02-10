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

Start by @seclink["Using_These_Docs"]{getting your bearings}. For an overview of the language, continue to @secref["Introduction_and_Usage"]. For a thorough orientation, @hyperlink["https://www.youtube.com/watch?v=XkIoGmWkEpM"]{watch the original video} from RacketCon 2021.

@table-of-contents[]

@section{Using These Docs}

@secref["Introduction_and_Usage"] describes the language and how to optimize your editor of choice to effectively write Qi. Learn the language by going through the @secref["Tutorial"], and read @secref["When_Should_I_Use_Qi_"] for examples illustrating its use. The many ways in which Qi may be used from the host language (e.g. Racket), as well as the ways in which Qi may be used in tandem with other DSLs, are described in @secref["Language_Interface"]. The various built-in forms of the language are documented in @secref["Qi_Forms"], while @secref["Qi_Macros"] covers using macros to extend the language. The @secref["Field_Guide"] contains practical advice.

@include-section["intro.scrbl"]
@include-section["tutorial.scrbl"]
@include-section["interface.scrbl"]
@include-section["forms.scrbl"]
@include-section["macros.scrbl"]
@include-section["field-guide.scrbl"]
@include-section["using-qi.scrbl"]
