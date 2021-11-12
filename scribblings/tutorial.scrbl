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

@title{Tutorial: When Should I Use Qi?}

Let's look at a collection of examples that may help shed light on when you should use Qi vs Racket or another language.

@table-of-contents[]

@section{Hadouken!}

When you're interested in transforming values, Qi is often the right language to use.

@subsection{Super Smush Numbers}

Let's say we'd like to define a function that adds together all of the input numbers, except that instead of using usual addition, we want to just adjoin them ("smush them") together to create a bigger number as the result.

In Qi, we could express it this way:

@codeblock{
  (define-flow smush
    (~> (>< ->string)
        string-append
        ->number))
}

The equivalent in Racket would be:

@codeblock{
  (define (smush . vs)
    (->number
     (apply string-append
            (map ->string vs))))
}

The Qi version uses @racket[><] to "map" all input values under the @racket[->string] flow to convert them to strings. Then it appends these values together as strings, finally converting the result back to a number to produce the result.

The Racket version needs to be parsed in detail in order to be understood, while the Qi version reads sequentially in the natural order of the transformations, and makes plain what these transformations are. Qi is the natural choice here.

The documentation for the @seclink["top" #:doc '(lib "scribblings/threading.scrbl")]{threading macro} contains additional examples of such transformations which to a first approximation apply to Qi as well (see @secref["Relationship_to_the_Threading_Macro"]).

@subsection{Root-Mean-Square}

While you can always use Qi to express computations as flows, it isn't always a better way of thinking about them -- just a @emph{different} way, better in some cases but not others. Let's look at an example that illustrates this subjectivity.

The "root mean square" is a measure often used in statistics to estimate the magnitude of some quantity for which there are many independent measurements. For instance, given a set of values representing the "deviation" of the result from the predictions of a model, we can use the square root of the mean of the squares of these values as an estimate of "error" in the model, i.e. inversely, an estimate of the accuracy of the model. The RMS also comes up in other branches of engineering and mathematics. What if we encountered such a case and wanted to implement this function? In Racket, we might implement it as:

@codeblock{
    (define (rms vs)
      (sqrt (/ (apply + (map sqr vs))
               (length vs))))
}

In Qi, it would be something like:

@codeblock{
    (define-flow rms
      (~> (-< (~> △ (>< sqr) +)
              length) / sqrt))
}

This first uses the tee junction, @racket[-<], to fork the input down two flows, one to compute the sum of squares and the other to compute the length. In computing the sum of squares, the input list is first separated into its component values using @racket[△]. Then, @racket[><] "maps" these values under the @racket[sqr] flow to yield the squares of the input values which are then summed. These values are combined downstream to yield the mean of the squares, whose square root produced as the result.

Here, there are reasons to favor either representation. The Racket version doesn't have too much redundancy so it is a fine way to express the computation. The Qi version eliminates the redundant references to the input (as it usually does), but aside from that it is primarily distinguished as being a way to express the computation as a series of transformations evaluated sequentially, while the Racket version expresses it as a compound expression to be evaluated hierarchically. They're just @emph{different} and neither is necessarily better.

@section{The Science of Deduction}

When you seek to analyze some values and make inferences or assertions about them, or take certain actions based on observed properties of values, or, more generally, when you seek to express anything exhibiting @emph{subject-predicate structure}, Qi is often the right language to use.

@subsection{Compound Predicates}

In Racket, if we seek to make a compound assertion about some value, we might do something like this:

@codeblock{
  (λ (num)
    (and (positive? num)
         (integer? num)
         (= 0 (remainder num 3))))
}

This recognizes positive integers divisible by three. Using the utilities in @secref["Additional_Higher-Order_Functions"
         #:doc '(lib "scribblings/reference/reference.scrbl")], we might write it as:

@codeblock{
  (conjoin positive?
           integer?
           (compose (curry = 0) (curryr remainder 3)))
}

... which avoids the wrapping lambda, doesn't mention the argument redundantly, and transparently encodes the fact that the function is a compound predicate. On the other hand, it is arguably less easy on the eyes. For starters, it uses the word "conjoin" to avoid colliding with "and," to refer to a similar idea. It also uses the words "curry" and "curryr" to partially apply functions, which are somewhat gratuitous as ways of saying "equal to zero" and "remainder by three."

In Qi, this would be written as:

@codeblock{
  (and positive?
       integer?
       (~> (remainder 3) (= 0)))
}

They say that perfection is achieved not when there is nothing left to add, but when there is nothing left to take away. Well then.

@subsection{abs}

Let's say we want to implement @racket[abs]. This is a function that returns the absolute value of the input argument, i.e. the value unchanged if it is positive, and negated otherwise -- a conditional transformation. With Racket, we might implement it like this:

@codeblock{
    (define (abs v)
      (if (negative? v)
          (- v)
          v))
}

For this very simple function, the input argument is mentioned @emph{four} times! An equivalent Qi definition is:

@codeblock{
    (define-switch abs-value
      [negative? -]
      [else _])
}

This uses the definition form of @racket[switch], which is a flow-oriented conditional analogous to @racket[cond]. The @racket[_] symbol here indicates that the input is to be passed through unchanged, i.e. it is the trivial or identity flow. The input argument is not mentioned; rather, the definition expresses @racket[abs] as a conditioned transformation of the input, that is, the essence of what this function is.

@section{What Flows?}

The classic Computer Science textbook, "The Structure and Interpretation of Computer Programs," contains the famous "metacircular evaluator" -- a Scheme interpreter written in Scheme. The code given for the @racket[eval] function is:

@codeblock{
    (define (eval exp env)
      (cond [(self-evaluating? exp) exp]
            [(variable? exp) (lookup-variable-value exp env)]
            [(quoted? exp) (text-of-quotation exp)]
            [(assignment? exp) (eval-assignment exp env)]
            [(definition? exp) (eval-definition exp env)]
            [(if? exp) (eval-if exp env)]
            [(lambda? exp)
             (make-procedure (lambda-parameters exp)
                             (lambda-body exp)
                             env)]
            [(begin? exp)
             (eval-sequence (begin-actions exp) env)]
            [(cond? exp) (eval (cond->if exp) env)]
            [(application? exp)
             (apply (eval (operator exp) env)
                    (list-of-values (operands exp) env))]
            [else
             (error "Unknown expression type -- EVAL" exp)]))
}

If we attempt to express this using flows exclusively, we might end up with something like this:

@codeblock{
    (define-switch eval
      [(~> 1> self-evaluating?) 1>]
      [(~> 1> variable?) lookup-variable-value]
      [(~> 1> quoted?) (~> 1> text-of-quotation)]
      [(~> 1> assignment?) eval-assignment]
      [(~> 1> definition?) eval-definition]
      [(~> 1> if?) eval-if]
      [(~> 1> lambda?) (~> (== (-< lambda-parameters
                                   lambda-body)
                               _)
                           make-procedure)]
      [(~> 1> begin?) (~> (== begin-actions
                              _)
                          eval-sequence)]
      [(~> 1> cond?) (~> (== cond->if
                             _)
                         eval)]
      [(~> 1> application?) (~> (-< (~> (== operator
                                            _) eval)
                                    (~> (== operands
                                            _) △ (>< eval)))
                                apply)]
      [else
       (error "Unknown expression type -- EVAL" 1>)])
}

While this eliminates more than thirty mentions of the inputs to the function in the Racket version, this version introduces a handful of flow references of its own (i.e. @racket[1>]) and is arguably no more clear than the original -- perhaps more daunting still.

Just because we @emph{can} always frame things as a flow, doesn't mean it's always the most natural way to express the computation. Follow what the computation wants to do, not what you want it to do. In the present case, the function is engaged in evaluating an expression in some environment. It is the expression we are concerned with transforming in some way, with the environment merely providing context. Arguably, therefore, it is the @emph{expression} that flows here, in the @emph{context} of an environment. By modeling the computation this way, we get the following implementation:

@codeblock{
    (define (eval exp env)
      (switch (exp)
        [self-evaluating? _]
        [variable? (lookup-variable-value env)]
        [quoted? text-of-quotation]
        [assignment? (eval-assignment env)]
        [definition? (eval-definition env)]
        [if? (eval-if env)]
        [lambda?
         (~> (-< lambda-parameters
                 lambda-body)
             (make-procedure env))]
        [begin?
          (~> begin-actions (eval-sequence env))]
        [cond? (~> cond->if (eval env))]
        [application?
         (~> (-< (~> operator (eval env))
                 (~> operands (list-of-values env) △))
             apply)]
        [else
         (error "Unknown expression type -- EVAL" _)]))
}

This version makes use of partial application @seclink["Templates_and_Partial_Application"]{templates}, making it a hybrid of Racket and Qi. It eliminates two dozen redundant references to the input expression, and contains almost no syntactic redundancy (unlike the preceding Qi implementation), making it the most clear of the three.

This illustrates that while many computations are naturally expressed as flows, it's important to ask just @emph{what} is flowing. Sometimes, this is less apparent than at other times. In such cases, don't try too hard to coerce the computation into one way of looking at things or one language. It's less important to be consistent and more important to be clear.

Still, some may say, well I don't agree with this assessment at all. Saying that the expression is what flows is subjective and poorly substantiated. It is both the expression @emph{and} the environment that flow here. Alright, well, pushed to take another look at our first attempt at writing this entirely with flows, we may notice that, really, the predicates are all only concerned with the input expression, while the consequent expressions are concerned with both the expression as well as the environment. What if, instead of the switch simply passing all inputs to all of its component flows, what if we could just indicate to the switch how it should direct these values, at the floodgates, as it were? That way, we could say that the predicates get only the first input, and the consequent expressions get all of the inputs. What if it worked that way? What if, indeed.

@section{Using the Right Tool for the Job}

These examples hopefully illustrate an age-old doctrine -- use the right tool for the job. A language is the best tool of all, so use the right language to express the task at hand. Sometimes, that language is Qi and sometimes it's Racket and sometimes it's a combination of the two, or something else. Employing a collection of general purpose and specialized languages, perhaps, is the best way to flow!
