#lang scribble/doc
@require[scribble/manual
         scribble-abbrevs/manual
         scribble/example
         racket/sandbox
         scribble-math/dollar
         @for-label[qi
                    racket]]

@(define eval-for-docs
  (parameterize ([sandbox-output 'string]
                 [sandbox-error-output 'string]
                 [sandbox-memory-limit #f])
    (make-evaluator 'racket/base
                    '(require qi
                              (only-in racket/list range)
                              (only-in racket/function curry)
                              racket/string)
                    '(define (sqr x)
                       (* x x)))))

@title{Tutorial}

This tutorial is available in two formats:

@itemlist[#:style 'ordered
          @item{An interactive format for you to go through and run yourself. (@bold{Recommended!})}
          @item{As standard Scribble documentation.}]

They contain similar material, but the interactive version includes additional steps and exercises. The interactive format is a more efficient and effective way to learn than reading documentation, and is recommended.

@table-of-contents[]

@section{Interactive Tutorial}

This tutorial is distributed using the @seclink["top" #:indirect? #t #:doc '(lib "from-template/scribblings/from-template.scrbl")]{Racket Templates} package, and contains the same material as the documentation-based tutorial, but also includes additional material such as exercises, all presented in an interactive format.

@subsection[#:tag "tutorial-installation"]{Installation}

If you don't already have @seclink["top" #:indirect? #t #:doc '(lib "from-template/scribblings/from-template.scrbl")]{Racket Templates} installed, you'll need to run this first:

@codeblock{
  raco pkg install from-template
}

And then, downloading the tutorial is as simple as:

@codeblock{
  raco new qi-tutorial
}

... and opening the file @code{start.rkt} in your favorite editor.

@subsection{Setup}

  The tutorial is structured as a collection of Racket modules that you can interactively run, allowing you to experiment with each form as you hone your understanding. To do this most effectively, follow the instructions below for your chosen editor.

@subsubsection[#:tag "drracket-tutorial"]{DrRacket}

  Laurent Orseau's @code{select-send-sexpr} @seclink["top" #:indirect? #t #:doc '(lib "quickscript/scribblings/quickscript.scrbl")]{quickscript} allows you to evaluate expressions on-demand in a context-sensitive way. It is essential for the interactive experience. Follow the instructions @hyperlink["https://github.com/countvajhula/qi-tutorial"]{in the README} to install it. Once installed, you can use @code{Control-Shift-Enter} (customizable) to evaluate the expression indicated (and usually highlighted) by your cursor position.

@subsubsection{Emacs}

  The native Emacs experience in Racket Mode is already geared towards interactive evaluation, so you should be all set. If you use modal editing, however, I recommend trying @hyperlink["https://github.com/countvajhula/symex.el"]{Symex.el}, which was designed with interactive evaluation in mind and provides a seamless experience here (disclosure: I'm the author!).

@subsubsection{Vim}

D. Ben Knoble's @seclink["top" #:indirect? #t #:doc '(lib "tmux-vim-demo/scribblings/tmux-vim-demo.scrbl")]{tmux-vim-demo} allows you to run expressions on demand with a split-pane view of your Vim buffer and a tmux session containing a Racket REPL. See @hyperlink["https://github.com/countvajhula/qi-tutorial"]{the README} for additional setup instructions once the package is installed. Once set up, you can simply use @code{r} (in Normal mode) to send the current line or visual selection to the REPL.

@section{Online Tutorial}

If you'd like to just go through the tutorial in documentation format, read on.

Qi is a general-purpose functional language, but it isn't a @hash-lang[], it's just a library. You can use it in any module just by:

@examples[
    #:eval eval-for-docs
    #:label #f
    (require qi)
  ]

The basic way to write a flow is to use the @racket[☯] form. A flow defined this way evaluates to an ordinary function, and you can pass input values to the flow by simply invoking this function with arguments.

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
  ]

... where underscores can be used to indicate argument positions.

@examples[
    #:eval eval-for-docs
    #:label #f
    ((☯ (string-append "a" _ "c")) "b")
  ]

You can use flows anywhere that you would normally use a function (since flows are just functions). As an example, if you wanted to double every element in a list of numbers, you could use:

@examples[
    #:eval eval-for-docs
    #:label #f
    (map (☯ (* 2)) (range 10))
  ]

... rather than use currying:

@examples[
    #:eval eval-for-docs
    #:label #f
    (map (curry * 2) (range 10))
  ]

... or the naive approach using a lambda:

@examples[
    #:eval eval-for-docs
    #:label #f
    (map (λ (v) (* v 2)) (range 10))
  ]

👉 Flows are often more clear than using currying, and can also be preferable to using a lambda in many cases.

Literals are interpreted as flows generating them.

@examples[
    #:eval eval-for-docs
    #:label #f
    ((☯ "hello") 3)
  ]

More generally, you can generate the result of any Racket expression as a flow by using @racket[gen] (short for generate or "genesis" -- to create or produce):

@examples[
    #:eval eval-for-docs
    #:label #f
    ((☯ (gen (+ 3 5))))
  ]

Flows like these that simply generate values always disregard any inputs you pass in.

@examples[
    #:eval eval-for-docs
    #:label #f
    ((☯ "hello") 3)
    ((☯ (gen (+ 3 5))) "a" "b" 'hi 1 2 3)
  ]

👉 @racket[gen] is a common way to incorporate any Racket expression into a flow.

When an underscore is used as a flow (rather than in an argument position, as above), it is the "identity" flow, which simply passes its inputs through, unchanged.

@examples[
    #:eval eval-for-docs
    #:label #f
    ((☯ _) 3 4 5)
  ]

Sometimes, it's useful to give flows a name, so that we can use them with different inputs in different cases. As flows evaluate to ordinary functions, we can name them the same way as any other function.

@examples[
    #:eval eval-for-docs
    #:label #f
    (define double (☯ (* 2)))
    (double 5)
  ]


But Qi also provides a dedicated flow definition form so you can be more explicit that you are defining a flow, and then you don't need to use @racket[☯].

@examples[
    #:eval eval-for-docs
    #:label #f
    (define-flow double (* 2))
    (double 5)
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

In Racket, if we wanted to evaluate an expression in terms of some inputs, we could wrap the expression in a lambda and immediately apply it to those input arguments:

@examples[
    #:eval eval-for-docs
    #:label #f
    ((λ (x y)
       (add1 (sqr (+ x y))))
     3 5)
  ]

But usually, we'd just use the more convenient @racket[let] form to do the same thing:

@examples[
    #:eval eval-for-docs
    #:label #f
    (let ([x 3] [y 5])
      (add1 (sqr (+ x y))))
  ]

Qi provides an analogous form, @racket[on], which allows you to apply a flow immediately to inputs.

@examples[
    #:eval eval-for-docs
    #:label #f
    (on (3 5)
      (~> + sqr add1))
  ]

Very often, the kind of flow that we want to apply immediately to inputs is a sequential one, i.e. a "threading" flow. So Qi provides an even more convenient shorthand for this common case.

@examples[
    #:eval eval-for-docs
    #:label #f
    (~> (3 5) + sqr add1)
  ]

... which is similar to the widely used "threading macro," but is a more general version as it has access to all of Qi.

Flows may divide values.

@examples[
    #:eval eval-for-docs
    #:label #f
    ((☯ (-< add1 sub1)) 3)
    ((☯ (-< + -)) 3 5)
  ]

This @racket[-<] form is called a "tee junction," named after a common pipe fitting used in plumbing to divide a flow down two pipes. It is also, of course, a Unix utility that performs a similar function for the input and output of Operating System processes.

Flows may channel values through flows in parallel.

@examples[
    #:eval eval-for-docs
    #:label #f
    ((☯ (== add1 sub1)) 3 7)
  ]

The @racket[==] form is called a "relay." Think of it as a "relay race" where the values flow along parallel tracks. "Relay" is also a radio device that retransmits an input signal.

You could also pass all input values independently through a common flow.

@examples[
    #:eval eval-for-docs
    #:label #f
    ((☯ (>< sqr)) 3 4 5)
  ]

This @racket[><] form is called an "amp," analogous to "map" for lists, and also as it can be thought of as transforming or "amplifying" the inputs under some flow.

👉 Flows compose naturally, so that the entire Qi language is available to define each flow component within a larger flow.

@examples[
    #:eval eval-for-docs
    #:label #f
    #:no-result
    (☯ (~> (-< sqr (* 2) 1) +))
  ]

What do you think this flow computes? Take a minute to study it, see if you can work it out.

First, we see that the flow divides the input value down three flows that each transform the input in some way. The parallel outputs of these three flows are then fed into the addition flow, so that these results are added together. Note that the third branch in the tee junction is just the literal value, @$["1"]. Since it is a literal, it is interpreted (as we saw earlier) as a flow that generates that literal value, regardless of any inputs. So, the first two branches of the tee junction square and double the input, respectively, while the third branch simply outputs the constant value, @$["1"]. Putting it all together, this flow computes the formula @$["x² + 2x + 1"]. Let's apply it to an input using the threading shorthand:

@examples[
    #:eval eval-for-docs
    #:label #f
    (~> (3) (-< sqr (* 2) 1) +)
  ]

The equivalent Racket expression is:

@examples[
    #:eval eval-for-docs
    #:label #f
    (let ([x 3]) (+ (sqr x) (* x 2) 1))
  ]

Why would we favor the Qi version here? Well, we wouldn't necessarily, but it has a few advantages: it doesn't mention the input value at all, while the Racket version mentions it 3 times. It's shorter. And most importantly, it encodes more information about the computation syntactically than the Racket version does. In what way? Well, with the Racket version, we don't know what the expression is about to do with the input value. It might transform it, or it might condition on it, or it might disregard it altogether. We need to @emph{read} the entire expression to determine the type of computation. With the Qi version, we can see that it is a sequential transformation just by looking.

Since we often work with lists in Racket, whereas we usually work with values in Qi, it is sometimes useful to separate an input list into its component values using a "prism."

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

... in analogy with the effect that prisms have on light -- separating white light into its component colors, and reconstituting them back into white light. Like this:

@examples[
    #:eval eval-for-docs
    #:label #f
    ((☯ (~> △ ▽)) (list 1 2 3))
  ]

You can also swap the prisms the get an identity transformation on values, instead.

@examples[
    #:eval eval-for-docs
    #:label #f
    ((☯ (~> ▽ △)) 1 2 3)
  ]

Note that this isn't exactly like the behavior with light, since with light, if you swapped the prisms their effect would be the same as before. There's no such thing as an "upside down" prism in an absolute sense with light -- the second one is "upside down" only in relation to the initial prism, and swapping the order of the prisms doesn't change this aspect. The same prism may separate or combine light, just depending on where it is in the sequence.

With Qi prisms, though, @racket[△] and @racket[▽] are different forms that do different things. @racket[△] separates, and @racket[▽] collects. Therefore, they have a different effect when swapped, and, for instance, this would be an error:

@examples[
    #:eval eval-for-docs
    #:label #f
    (eval:error ((☯ (~> △ ▽)) 1 2 3))
  ]

... because △ cannot "separate" what is already separated -- it expects a single input list.

👉 @racket[△] and @racket[▽] often allow you to avoid using @racket[list] and @racket[apply].

For instance:

@examples[
    #:eval eval-for-docs
    #:label #f
    (~>> ((list 3 4 5)) (map sqr) (apply +))
  ]

This flow computes the sum of the squares of three values. We use map and apply here because the input happens to be in the form of a list. Instead, we could use a prism to separate the list into its component values, allowing us to use the flows on values directly:

@examples[
    #:eval eval-for-docs
    #:label #f
    (~> ((list 3 4 5)) △ (>< sqr) +)
  ]

One way to think about flows is that they are a way to compose functions in complex ways. One type of function that we compose often is a @emph{predicate}, that is, a boolean-valued function that answers a question about its inputs.

Predicates can be composed by using @racket[and], @racket[or], and @racket[not].

@examples[
    #:eval eval-for-docs
    #:label #f
    (on (27)
      (and positive?
           integer?
           (~> (remainder 3) (= 0))))
  ]

This answers whether the input is a positive integer divisible by 3, which, in this case, it is.

👉 As with any flow, we can give this one a name. In practice, this is an elegant way to define predicates.

@examples[
    #:eval eval-for-docs
    #:label #f
    (define-flow threeish?
      (and positive?
           integer?
           (~> (remainder 3) (= 0))))

    (threeish? 27)
    (threeish? 32)
  ]

We often use predicates in conditional expressions such as @racket[if] or @racket[cond].  Since this pattern is so common, Qi provides a dedicated conditional form called @racket[switch] which allows you to use flows as your conditions as well as the transformations to perform on the inputs if the conditions hold. This form is useful in cases where the result of the conditional expression is a function of its inputs. This is a very common case. Take a moment to scan through a favorite Racket project you worked on. Look for @racket[cond] expressions where every condition answers a question about the same value or the same set of values. Every one of these cases (and more) are cases where you needed @racket[switch] but didn't have it. Well, now you do! Let's look at what it does.

@racket[switch] looks a lot like @racket[cond], except that every one of its condition and consequent clauses is a flow. These flows typically all receive the same inputs -– the original inputs to the switch expression.

@examples[
    #:eval eval-for-docs
    #:label #f
    (switch (3)
      [positive? add1]
      [negative? sub1]
      [else _])
  ]

Let's try this with a few different inputs. Instead of writing it from scratch each time, let's give this flow a name. As we saw earlier, we could do this in the usual way with define:

@examples[
    #:eval eval-for-docs
    #:label #f
    (define amplify
      (☯ (switch [positive? add1]
                 [negative? sub1]
                 [else _])))
  ]

... which also reveals how the switch form is just like @racket[~>] in that it is just a form of the Qi language. Since it represents another common case, Qi provides the shorthand @racket[switch] form that we used above, which can be used at the Racket level alongside forms like @racket[cond], without having to enter Qi via @racket[☯].

Using @racket[define] is one way to give this flow a name. Another way is to use the dedicated @racket[define-switch] form provided by Qi, which is more explicit:

@examples[
    #:eval eval-for-docs
    #:label #f
    (define-switch amplify
      [positive? add1]
      [negative? sub1]
      [else _])

    (amplify 3)
    (amplify -3)
    (amplify 0)
  ]

As flows accept any number of input values, the predicates we define and use (for instance with switch) can operate on multiple values as well. The following flow computes the absolute difference between two input values:

@examples[
    #:eval eval-for-docs
    #:label #f
    (define-values (a b) (values 3 5))

    (switch (a b)
      [> -]
      [< (~> X -)])
  ]

The @racket[X] or "crossover" form used here reverses the order of the inputs, and ensures here that the larger argument is passed to the subtract operation in the first position.

Finally, we can end flows by using the @racket[ground] form.

@examples[
    #:eval eval-for-docs
    #:label #f
    ((☯ ⏚) 3 4 5)
  ]

This produces no values at all, and is useful in complex flows where we may wish to end certain branches of the flow based on predicates or some other criteria. As an example, the following flow sums all input numbers that are greater than 3.

@examples[
    #:eval eval-for-docs
    #:label #f
    ((☯ (~> (>< (if (> 3) _ ⏚))
            +)) 1 3 5 2 7)
  ]

... which uses a flow version of @racket[if] where the condition, consequent, and alternative expressions are all flows operating on the inputs. We could use a switch too, of course, but @racket[if] is simpler here. As is the case with any complex language, there are many ways of saying the same thing in Qi. In this particular case, as it happens, Qi has a more convenient shorthand, @racket[pass], which only allows values through that meet some criterion.

@examples[
    #:eval eval-for-docs
    #:label #f
    ((☯ (~> (pass (> 3)) +)) 1 3 5 2 7)
  ]

We've now learned about the @racket[☯], @racket[on], @racket[~>], and @racket[switch] forms, which are ways to enter the Qi language. We've learned many of the forms of the Qi language and how they allow us to describe computations in terms of complex flows that direct multiple values through bifurcating and recombining sequences of transformations to arrive at the result.

We've also learned that we can give names to flows via @racket[define-flow], and @racket[define-switch].

Qi provides lots of other forms that allow you to express flows conveniently and elegantly in different contexts. You can see all of them in the grammar of the @racket[☯] form, and they are individually documented under @secref["Qi_Forms"].

Next, let's look at some examples to gain some insight into @seclink["When_Should_I_Use_Qi_"]{when to use Qi}.

@close-eval[eval-for-docs]
@(set! eval-for-docs #f)
