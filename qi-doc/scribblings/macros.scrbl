#lang scribble/doc
@require[scribble/manual
         scribble-abbrevs/manual
         scribble/example
         racket/sandbox
         @for-label[qi
                    racket
                    syntax/parse
                    syntax/parse/define]]

@(define eval-for-docs
  (parameterize ([sandbox-output 'string]
                 [sandbox-error-output 'string]
                 [sandbox-memory-limit #f])
    (make-evaluator 'racket/base
                    '(require qi
                              (only-in racket/list range first rest)
                              (for-syntax syntax/parse racket/base)
                              racket/string)
                    '(define (sqr x)
                       (* x x)))))

@title[#:tag "Qi_Macros"]{Qi Macros}

Qi may be extended in much the same way as Racket -- using @tech/reference{macros}. Qi macros are indistinguishable from built-in Qi forms during the macro expansion phase, just as user-defined Racket macros are indistinguishable from macros that are part of the Racket language. This allows us to have the same syntactic freedom with Qi as we are used to with Racket, from being able to @seclink["Adding_New_Language_Features"]{add new language features} to implementing @seclink["Writing_Languages_in_Qi"]{entire new languages} in Qi.

This "first class" macro extensibility of Qi follows the general approach described in @hyperlink["https://dl.acm.org/doi/abs/10.1145/3428297"]{Macros for Domain-Specific Languages (Ballantyne et. al.)}.

@table-of-contents[]

@section{Defining Macros}

These Qi macro definition forms mirror the corresponding forms for defining Racket macros. Note that if you use @seclink["stxparse-patterns" #:doc '(lib "syntax/scribblings/syntax.scrbl")]{syntax patterns} or @seclink["stxparse-specifying" #:doc '(lib "syntax/scribblings/syntax.scrbl")]{syntax classes} in your macro definition, or if you are manipulating syntax objects directly, you may need to @racket[(require (for-syntax syntax/parse racket/base))], just as you would in writing similar Racket macros.

@defform[(define-qi-syntax-rule (macro-id . pattern) pattern-directive ...
           template)]{

 Similar to @racket[define-syntax-parse-rule], this defines a Qi macro named @racket[macro-id], which may be used in any @tech{flow} definition. The @racket[template] is expected to be a Qi rather than Racket expression. You can @seclink["Using_Racket_to_Define_Flows"]{always use Racket} here via @racket[esc], of course.

  @examples[#:eval eval-for-docs
    (define-qi-syntax-rule (pare car-flo cdr-flo)
      (group 1 car-flo cdr-flo))

    (~> (3 6 9) (pare sqr +) ▽)
  ]
}

@defform[(define-qi-syntax-parser macro-id parse-option ... clause ...+)]{

 Similar to @racket[define-syntax-parser], this defines a Qi macro named @racket[macro-id], which may be used in any @tech{flow} definition. The @racket[template] in each clause is expected to be a Qi rather than Racket expression. You can @seclink["Using_Racket_to_Define_Flows"]{always use Racket} here via @racket[esc], of course.

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

 However, if the binding you define in this way collides with an identifier in Racket (for instance, if you call it @racket[cond]), it would override the Racket version (unlike using @racket[define-qi-syntax-rule] or @racket[define-qi-syntax-parser] where they exist in a distinct @tech/reference{binding space}). To avoid this, use @racket[define-qi-syntax] instead of @racket[define-syntax].

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

 Qi macros are bindings just like Racket macros. In order to use them, simply @seclink["Defining_Macros"]{define them}, and if necessary, @racket[provide], and @racket[require] them in the relevant modules, with the proviso below regarding "binding spaces." Once defined and in scope, Qi macros are indistinguishable from built-in @seclink["Qi_Forms"]{Qi forms}, and may be used in any @tech{flow} definition just like the built-in forms.

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

@section{Adding New Language Features}

When you consider that Racket's @seclink["classes" #:doc '(lib "scribblings/guide/guide.scrbl")]{class-based object system} for object-oriented programming is implemented with Racket macros in terms of the underlying @seclink["structures" #:doc '(lib "scribblings/reference/reference.scrbl")]{struct type} system, it gives you some idea of the extent to which macros enable the addition of new language features, both great and small. In this section we'll look at a few examples of what Qi macros can do.

@subsection{Write Yourself a Maybe Monad for Great Good}

In functional languages such as Haskell, a popular way to do (or rather avoid) exception handling is to use the Maybe monad. Qi doesn't include monads out of the box yet, but you could implement a version of the Maybe monad yourself by using macros. But first, let's quickly review why you might want to in the first place.

Earlier, we @seclink["Overview" #:doc '(lib "qi/scribblings/qi.scrbl")]{drew a distinction} between two paradigms employed in programming languages: one organized around the flow of @emph{control} and another organized around the flow of @emph{data}. A way to manage possible errors in code along the lines of the former ("control") paradigm is to handle @emph{exceptions} that may occur at each stage, and take appropriate action -- for instance, abort the remainder of the computation. A second way to handle errors, more along the lines of the "flow of data" paradigm, is for the "failing" computation to simply produce a sentinel value that signifies an error, so that the sequence of operations does not actually fail but merely generates and propagates a value signifying failure. The trick is, how to do this in such a way that downstream computations are aware of the sentinel error value so that they don't attempt to perform computations on it that they might do on a "normal" value? This is where the Maybe monad comes in.

We want to thread values through a number of flows, and if any of those flows raises an exception, we'd like the entire @tech{flow} to generate @emph{no values}. Typically, we compose flows in series by using the @racket[~>] form. For flows that may fail, we need a similar form, but one that (1) handles failure of a particular @tech{flow} by producing no values, and (2) composes flows so that the entire @tech{flow} fails (i.e. produces no values) if any component fails.

Let's write each of these in turn and then put them together.

For the first, we write a macro that wraps any Qi @tech{flow} with the exception handling logic to generate no values.

@racketblock[
(define-qi-syntax-rule (get flo)
  (try flo [exn? ⏚]))
]

This uses Qi's @racket[try] form to catch any exceptions raised during execution of the @tech{flow}, handling them by simply generating no values as the result.

Now for the second part, in the binary case of two flows @racket[f] and @racket[g], either of which may fail to produce values, the composition could be defined as:

@racketblock[
(define-qi-syntax-rule (mcomp f g)
  (~> f (when live? g)))
]

... which only feeds the output of the first @tech{flow} to the second if there is any. Now, let's put these together to write our failure-aware threading form, that is to say, our Maybe monad.

@racketblock[
(define-qi-syntax-parser maybe~>
  [(_ flo)
   #'(get flo)]
  [(_ flo1 flo ...)
   #'(mcomp (get flo1) (maybe~> flo ...))])
]

This form is just like @racket[~>], except that it does two additional things: (1) It wraps each component @tech{flow} with the @racket[get] macro so that an exception would result in the @tech{flow} generating no values, and (2) it checks whether there are values flowing at all before attempting to invoke the next @tech{flow} on the outputs. Thus, if there is a failure at any point, the entire rest of the computation is short-circuited.

Note that short-circuiting isn't essential here as long as our composition ensures that the result is still well-defined if downstream @tech{flow} components are invoked with no values upon failure of an upstream component (and they should produce no values in this case). But as we already know the result at the first point of failure, it is more performant to avoid invoking subsequent flows at all rather than rely on repeated composition in a computation destined to produce no values, and indeed, most Maybe implementations do short-circuit in this manner.

@racketblock[
((☯ (maybe~> (/ 2) sqr add1)) 10)
((☯ (maybe~> (/ 0) sqr add1)) 10)
]

And there you have it, you've implemented the Maybe monad in about nine lines of Qi macros.

@subsection{Translating Foreign Macros}

Qi expects components of a @tech{flow} to be flows, which at the lowest level are functions. This means that Qi cannot naively be used with forms from the host language (or another DSL) that are @emph{macros}. If we didn't have @racket[define-qi-foreign-syntaxes] to register such "foreign-language macros" with Qi in a convenient way, we could still implement this feature ourselves, by writing corresponding Qi macros to wrap the foreign macros. The following example demonstrates how this might work.

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

@section{Writing Languages in Qi}

Just as Racket macros allow us to write new languages in Racket, Qi macros allow us to write new languages in Qi.

You may prefer to use Qi as your starting point if your language deals with the @tech{flow} of data, or if the semantics of the language are more easily expressed in Qi than in Racket. By starting from Qi, you inherit access to all of Qi's forms, extensions, and tools that have been designed with the @tech{flow} of data in mind – so you can focus on the specifics of your domain rather than the generalities of data @tech{flow}.

In general, macros that define new languages are called @deftech{interface macros}, since they form the interface between two languages. Languages fall into two classes depending on their use of interface macros. We'll learn about these two classes and then go over some examples to get a sense for when each type of language is called for.

@subsection{Embedded Languages}

One class of language has as many @tech["interface macros"] as there are forms in the language, so that the language seamlessly extends the host language. Such languages are called embedded languages or @deftech{embedded DSLs}. Examples of embedded languages in the Racket ecosystem include @seclink["top" #:indirect? #t #:doc '(lib "deta/deta.scrbl")]{Deta}, @seclink["top" #:indirect? #t #:doc '(lib "sawzall-doc/sawzall.scrbl")]{Sawzall}, Racket's built-in @seclink["contracts" #:doc '(lib "scribblings/reference/reference.scrbl")]{contract DSL}, @seclink["top" #:indirect? #t #:doc '(lib "contract/social/scribblings/social-contract.scrbl")]{Social Contract}, and @seclink["top" #:indirect? #t #:doc '(lib "scribblings/megaparsack.scrbl")]{Megaparsack}.

Embedded languages implicitly inherit the semantics of the host language (but may define and employ custom semantics, even predominantly). With Qi as the host language, this means that such languages are inherently flow-oriented, and could range from general-purpose "dialects" of Qi to specialized DSLs. They are perhaps the most common type of language one might write in Qi.

If your language would employ flows in a general way but with specialized data structures or idioms, then it may be a good candidate for implementation as an embedded Qi DSL.

If there is an existing such language already implemented in Racket that you'd like to treat as a Qi DSL, you can embed it into Qi by using @racket[define-qi-foreign-syntaxes], but note that this "extrinsic" embedding would not benefit from any @tech{flow} optimizations that may eventually be part of the Qi compiler, and incurs some administrative overhead.

@subsection{Hosted Languages}

It is also possible to implement your language as a @emph{single} macro or a small set of mutually reliant macros, with the bulk of the forms of the language specified as expansion rules within these macros. Such a language is called a @emph{hosted} language or @deftech{hosted DSL}, and each of the @tech["interface macros"] it is made up of could be considered to be hosted sublanguages. Examples of hosted languages include Racket's @racket[match], and Qi itself, and typically (as in these examples) they are defined via a single interface macro containing all of the rules of the language.

The advantage of writing a hosted DSL, in general, is that by introducing a level of indirection between your code and the host-language (e.g. Racket or Qi) expander, you gain access to a distinct namespace that does not interfere with the names in the host language, allowing you greater syntactic freedom (for instance, to name your forms @racket[and] and @racket[if], which would otherwise collide with forms of the same name in the host language). In addition, you gain control over the expansion process, allowing you to, for instance, add a custom compiler to optimize the expanded forms of your language before host language expansion takes over.

If you are interested in writing a hosted language that you'd like to use from within Qi, there are two options. You could either write the language as a Qi macro, or as a Racket macro and leverage it via Qi's @racket[esc]. In the latter case, you could even write a Qi "bridge" macro that transparently employs @racket[esc]. These two options are functionally equivalent, but if your language is data-oriented it may make more sense for it to compile to Qi so that it can leverage any @tech{flow} optimizations that may eventually be part of the Qi compiler.

@subsection{Embedding a Hosted Language}

You can always embed a hosted language into the host language by implementing a set of macros corresponding to each form of the language. For languages that are large enough, this may be the best option to gain the advantages of a hosted language while also retaining the convenience of an embedded one for special cases. For instance, for a small embedded version of Qi, you could do:

@racketblock[
(define-syntax-parse-rule (~> (arg ...) flo ...)
  (on (arg ...) (~> flo ...)))
(define-syntax-parse-rule (>< (arg ...) flo)
  (on (arg ...) (>< flo)))
(define-syntax-parse-rule (-< (arg ...) flo ...)
  (on (arg ...) (-< flo ...)))
(define-syntax-parse-rule (== (arg ...) flo ...)
  (on (arg ...) (== flo ...)))
]

And this would allow you to use Qi forms directly in Racket -- indeed, the forms in the @secref["Language_Interface"] are such embeddings of Qi into Racket. The same approach would also work to embed a hosted DSL into Qi, whether that DSL is hosted on Qi or Racket.

@subsubsection{Exercise: Pattern Matching}

Let's add some @seclink["match" #:doc '(lib "scribblings/guide/guide.scrbl")]{pattern matching} to Qi by embedding Racket's pattern matching language into Qi, using this approach.

First, the simplest possible embedding of @racket[match] is to just write a Qi macro corresponding to the Racket macro.

@racketblock[
(define-qi-syntax-rule (match [pats body] ...)
  (esc (λ args
         (match/values (apply values args)
           [pats (apply (flow body) args)]
           ...))))
]

This @seclink["Converting_a_Macro_to_a_Flow"]{converts the foreign macro to a flow} in the usual way, i.e. by wrapping it in a lambda and using it via @racket[esc], as discussed earlier. Note that it expects the body of the match clauses to be @emph{Qi} rather than Racket, and any identifiers bound by pattern matching would be in scope in these flows since that is what @racket[match] does. Let's use it:

@racketblock[
(~> (5 (list 1 2 3))
    (match
      [(n (list a b c)) (gen n (+ a b c))]
      [(n (cons v vs)) 'something-else]))
]

This is great, but in practice we are often interested in using pattern matching just for @emph{destructuring} the input, and already know the pattern it is going to match. It would be nice to have a more convenient form to use in such cases. We can do this by writing a second macro to embed this narrower functionality into Qi.

@racketblock[
(define-qi-syntax-rule (pat pat-clause body ...)
  (match [pat-clause body ...]))
]

And now:

@racketblock[
(~> (5 (list 1 2 3))
    (pat (n (list a b c)) (gen n (+ a b c))))
(~> (1 2 3) (pat (_ (? number?) x) +))
]

Similarly, we could write more such embeddings to simplify other common cases, such as matching against a single input value. Thus, the features provided by one language may be embedded into another language.

@close-eval[eval-for-docs]
@(set! eval-for-docs #f)
