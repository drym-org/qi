#lang scribble/doc
@require[scribble/manual
         scribble-abbrevs/manual
         scribble/example
         racket/sandbox
         @for-label[qi
                    racket
                    syntax/parse
                    syntax/parse/define
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
                              (only-in racket/list range first rest)
                              (for-syntax syntax/parse racket/base)
                              racket/string
                              relation)
                    '(define (sqr x)
                       (* x x)))))

@title{Qi Macros}

Qi may be extended in much the same way as Racket -- using @tech/reference{macros}. Qi macros are indistinguishable from built-in Qi forms during the macro expansion phase, just as user-defined Racket macros are indistinguishable from macros that are part of the Racket language. This allows us to have the same syntactic freedom with Qi as we are used to with Racket.

This "first class" macro extensibility of Qi follows the general approach described in @hyperlink["https://dl.acm.org/doi/abs/10.1145/3428297"]{Macros for Domain-Specific Languages (Ballantyne et. al.)}.

@table-of-contents[]

@section{Defining Macros}

@defform[(define-qi-syntax-rule (macro-id . pattern) pattern-directive ...
           template)]{

 Similar to @racket[define-syntax-parse-rule], this defines a Qi macro named @racket[macro-id], which may be used in any flow definition. The @racket[template] is expected to be a Qi rather than Racket expression. You can @seclink["Using_Racket_to_Define_Flows"]{always use Racket} here via @racket[esc], of course.

  @examples[#:eval eval-for-docs
    (define-qi-syntax-rule (pare car-flo cdr-flo)
      (group 1 car-flo cdr-flo))

    (~> (3 6 9) (pare sqr +) ▽)
  ]
}

@defform[(define-qi-syntax-parser macro-id parse-option ... clause ...+)]{

 Similar to @racket[define-syntax-parser], this defines a Qi macro named @racket[macro-id], which may be used in any flow definition. The @racket[template] in each clause is expected to be a Qi rather than Racket expression. You can @seclink["Using_Racket_to_Define_Flows"]{always use Racket} here via @racket[esc], of course.

  @examples[#:eval eval-for-docs
    (define-qi-syntax-parser pare
      [_:id #''hello]
      [(_ car-flo cdr-flo) #'(group 1 car-flo cdr-flo)])

    (~> (3 6 9) (pare sqr +) ▽)
    (~> (3 6 9) pare)
  ]
}

@defstruct[qi-macro ([transformer procedure?])
                    #:omit-constructor]{
 If you cannot use the forms above and instead need to define a macro using Racket's macro APIs directly, the only thing you'd need to do is wrap the resulting syntax parser as a @racket[qi-macro] type.

  @examples[#:eval eval-for-docs
    (require qi
            (for-syntax syntax/parse
                        racket/base))

    (define-syntax square
      (qi-macro
       (syntax-parser
         [(_ flo) #'(~> flo flo)])))

    (~> (5) (square add1))
  ]

 However, if the binding you define in this way collides with an identifier in Racket (for instance, if you call it @racket[cond]), it would override the Racket version (unlike using @racket[define-qi-syntax-rule] or @racket[define-qi-syntax-parser] where they exist in a distinct namespace). To avoid this, use @racket[define-qi-syntax] instead of @racket[define-syntax].

 Note that the type constructor @racket[qi-macro] is all that is publicly exported for this struct type (and only in the @techlink[#:doc '(lib "scribblings/reference/reference.scrbl") #:key "phase level"]{syntax phase}), since the details of its implementation are considered internal to the Qi library.
}

@defform[(define-qi-syntax macro-id transformer)]{

 Similar to @racket[define-syntax], this creates a @tech/guide{transformer binding} but uses the Qi @tech/reference{binding space}, so that macros defined this way will not override any Racket (or other language) forms that may have the same name. @racket[(define-qi-syntax macro-id transformer)] is approximately @racket[(define-syntax ((make-interned-syntax-introducer 'qi) macro-id) transformer)].

  @examples[#:eval eval-for-docs
    (define-qi-syntax cond
      (qi-macro
       (syntax-parser
         [(_ flo) #'(~> flo flo)])))

    (~> (5) (cond add1))
    (cond [#f 'hi]
          [else 'bye])
  ]

 Note that macros defined using this form @emph{must} wrap the resulting syntax parser as a @racket[qi-macro].
}

@section{Using Macros}

@emph{Note: This section is about using Qi macros. If you are looking for information on using macros of another language (such as Racket or another DSL) together with Qi, see @secref["Using_Racket_Macros_as_Flows"].}

 Qi macros are bindings just like Racket macros. In order to use them, simply @seclink["Defining_Macros"]{define them}, and if necessary, @racket[provide], and @racket[require] them in the relevant modules, with the proviso below regarding "binding spaces." Once defined and in scope, Qi macros are indistinguishable from built-in @seclink["Qi_Forms"]{Qi forms}, and may be used in any flow definition just like the built-in forms.

 In order to ensure that Qi macros are only usable within a Qi context and do not interfere with Racket macros that may happen to share the same name, Qi macros are defined so that they exist in their own @tech/reference{binding space}. This means that you must use the @racket[provide] subform @racket[for-space] in order to make Qi macros available for use in other modules. They may be @racketlink[require]{required} in the same way as any other bindings, however, i.e. indicating @racket[for-space] with @racket[require] is not necessary.

 To illustrate, the providing module would resemble this:

@racketblock[
  (provide (for-space qi pare))

  (define-qi-syntax-rule (pare car-flo cdr-flo)
    (group 1 car-flo cdr-flo))
]

And assuming the module defining the Qi macro @racket[pare] is called @racket[mac-module], then any of the following (among other variations) would import it into scope.

@racketblock[
  (require mac-module)
  (require (only-in mac-module pare))
]

@subsection{Racket Version Compatibility}

 As binding spaces were added to Racket in version 8.3, older versions of Racket will not be able to use the macros described here, but can still use the legacy @seclink["Language_Extension"]{@racket[qi:]-prefixed macros}.

@section{Example Macros}

When you consider that Racket's @seclink["classes" #:doc '(lib "scribblings/guide/guide.scrbl")]{class-based object system} for object-oriented programming is implemented with Racket macros in terms of the underlying @seclink["structures" #:doc '(lib "scribblings/reference/reference.scrbl")]{struct type} system, it gives you some idea of the extent to which macros enable the addition of new language features, both great and small. In this section we'll look at a few examples of what Qi macros can do.

@subsection{Write Yourself a Maybe Monad for Great Good}

In functional languages such as Haskell, a popular way to do (or rather avoid) exception handling is to use the Maybe monad. Qi doesn't include monads out of the box yet, but you could implement a version of the Maybe monad yourself by using macros. But first, let's quickly review why you might want to in the first place.

Earlier, we @seclink["Overview" #:doc '(lib "qi/scribblings/qi.scrbl")]{drew a distinction} between two paradigms employed in programming languages: one organized around the flow of @emph{control} and another organized around the flow of @emph{data}. A way to manage possible errors in code along the lines of the former ("control") paradigm is to handle @emph{exceptions} that may occur at each stage, and take appropriate action -- for instance, abort the remainder of the computation. A second way to handle errors, more along the lines of the "flow of data" paradigm, is for the "failing" computation to simply produce a sentinel value that signifies an error, so that the sequence of operations does not actually fail but merely generates and propagates a value signifying failure. The trick is, how to do this in such a way that downstream computations are aware of the sentinel error value so that they don't attempt to perform computations on it that they might do on a "normal" value? This is where the Maybe monad comes in.

We want to thread values through a number of flows, and if any of those flows raises an exception, we'd like the entire flow to generate @emph{no values}. Typically, we compose flows in series by using the @racket[~>] form. For flows that may fail, we need a similar form, but one that (1) handles failure of a particular flow by producing no values, and (2) composes flows so that the entire flow fails (i.e. produces no values) if any component fails.

Let's write each of these in turn and then put them together.

For the first, we write a macro that wraps any Qi flow with the exception handling logic to generate no values.

@racketblock[
(define-qi-syntax-rule (try flo)
  (esc (λ args
         (with-handlers [(exn? (☯ ⏚))]
           (apply (☯ flo) args)))))
]

This form escapes to Racket in order to wrap the flow with exception handling. Any exceptions raised by execution of the flow result in the enclosing flow simply generating no values.

Now for the second part, in the binary case of two flows @racket[f] and @racket[g], either of which may fail to produce values, the composition could be defined as:

@racketblock[
(define-qi-syntax-rule (mcomp f g)
  (~> f (when live? g)))
]

... which only feeds the output of the first flow to the second if there is any. Now, let's put these together to write our failure-aware threading form, that is to say, our Maybe monad.

@racketblock[
(define-qi-syntax-parser maybe~>
  [(_ flo)
   #'(try flo)]
  [(_ flo1 flo ...)
   #'(mcomp (try flo1) (maybe~> flo ...))])
]

This form is just like @racket[~>], except that it does two additional things: (1) It wraps each component flow with the @racket[try] macro so that an exception would result in the flow generating no values, and (2) it checks whether there are values flowing at all before attempting to invoke the next flow on the outputs. Thus, if there is a failure at any point, the entire rest of the computation is short-circuited.

@racketblock[
((☯ (maybe~> (/ 2) sqr add1)) 10)
((☯ (maybe~> (/ 0) sqr add1)) 10)
]

And there you have it, you've implemented the Maybe monad in about eleven lines of Qi macros.

@subsection{Translating Foreign Macros}

Qi expects components of a flow to be flows, which at the lowest level are functions. This means that Qi cannot naively be used with forms from the host language (or another DSL) that are @emph{macros}. If we didn't have @racket[define-qi-foreign-syntaxes] to register such "foreign-language macros" with Qi in a convenient way, we could still implement this feature ourselves, by writing corresponding Qi macros to wrap the foreign macros. The following example demonstrates how this might work.

In @secref["Converting_a_Macro_to_a_Flow"], we learned that Racket macros could be used from Qi by employing @racket[esc] and wrapping the foreign macro invocation in a @racket[lambda]. To avoid doing this manually each time, we could write a Qi macro to make this syntactic transformation invisible. For instance:

@examples[
    #:eval eval-for-docs
    (define-syntax-rule (double-me x) (* 2 x))
    (define-syntax-rule (subtract-two x y) (- x y))
    (define-qi-syntax-parser subtract-two
      [_:id #'(esc (λ (x y) (subtract-two x y)))]
      [(_ y) #'(esc (λ (x) (subtract-two x y)))]
      [(_ (~datum _) y) #'(subtract-two y)]
      [(_ x (~datum _)) #'(esc (λ (y) (subtract-two x y)))])
    (define-qi-syntax-parser double-me
      [_:id #'(esc (λ (v) (double-me v)))])
    (~> (5) (subtract-two 4) double-me)
  ]

Note that the Qi macros can have the same name as the Racket macros since they exist in different @tech/reference{binding spaces} and therefore don't interfere with one another.

Of course, writing Qi macros for such cases in practice is unnecessary as there is @racket[define-qi-foreign-syntaxes] instead, which does this for you and in a robust and generally applicable way.
