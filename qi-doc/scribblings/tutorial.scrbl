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

@title{Tutorial}

@section{Interactive Tutorial}

This tutorial is available in interactive format as a collection of Racket modules that you can interactively run, allowing you to experiment with each form to hone your understanding. The interactive tutorial is distributed using the @other-doc['(lib "from-template/scribblings/from-template.scrbl")] package, and contains the same material as the documentation-based tutorial, but also includes additional exercises and steps. The interactive format is a more efficient and effective way to learn, and is recommended! Downloading it is as simple as:

@codeblock{
  raco new qi-tutorial
}

And then open the file @code{start.rkt} in your favorite editor. This assumes you already have @other-doc['(lib "from-template/scribblings/from-template.scrbl")] installed. If not, you'll need to run this first:

@codeblock{
  raco pkg install from-template
}

If you'd like to just go through the tutorial in standard documentation format, read on.

@section{Online Tutorial}

We'll first learn to write some simple flows. The basic way to write a flow is to use the @racket[☯] form. A flow defined this way evaluates to an ordinary function, and you can pass input values to the flow by simply invoking this function with arguments.

Ordinary functions are already flows.

@examples[
    #:eval eval-for-docs
    #:label #f
    ((☯ sqr) 3)
  ]

Ordinary functions can be partially applied using templates.

@examples[
    #:eval eval-for-docs
    #:label #f
    ((☯ (+ 2)) 3)
    ((☯ (string-append "a" _ "c")) "b")
  ]

Literals are interpreted as flows generating them.

@examples[
    #:eval eval-for-docs
    #:label #f
    ((☯ "hello") 3)
  ]

Values can be "threaded" through multiple flows in sequence.

@examples[
    #:eval eval-for-docs
    #:label #f
    ((☯ (~> sqr add1)) 3)
  ]

More than one value can flow.

@examples[
    #:eval eval-for-docs
    #:label #f
    ((☯ (~> + sqr add1)) 3 5)
  ]

Since threading values through flows in sequence is so common, you can use a shorthand to immediately invoke such a sequential flow on input values.

@examples[
    #:eval eval-for-docs
    #:label #f
    (~> (3 5) + sqr add1)
  ]

Flows may divide values.

@examples[
    #:eval eval-for-docs
    #:label #f
    ((☯ (-< add1 sub1)) 3)
    ((☯ (-< + -)) 3 5)
  ]

Flows may channel values through flows in parallel.

@examples[
    #:eval eval-for-docs
    #:label #f
    ((☯ (== add1 sub1)) 3 7)
  ]

You could also pass all input values independently through a common flow.

@examples[
    #:eval eval-for-docs
    #:label #f
    ((☯ (>< sqr)) 3 4 5)
  ]

Predicates can be composed by using @racket[and], @racket[or], and @racket[not].

@examples[
    #:eval eval-for-docs
    #:label #f
    ((☯ (and positive? integer? (not odd?))) 2)
  ]

It is sometimes useful to separate an input list into its component values using a "prism."

@examples[
    #:eval eval-for-docs
    #:label #f
    ((☯ (~> △ +)) (list 1 2 3))
  ]

... or constitute a list out of values using an "upside-down prism."

@examples[
    #:eval eval-for-docs
    #:label #f
    ((☯ (~> (>< sqr) ▽)) 1 2 3)
  ]

And those are the basics. Next, let's look at some examples to gain some insight into @seclink["When_Should_I_Use_Qi_"]{when to use Qi}.
