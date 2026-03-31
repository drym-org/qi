#lang scribble/doc
@require[scribble/manual
         (for-label qi
                    racket/list
                    racket/base)]

@title{List Operations}

@defmodule[qi/list]

This module defines functional list operations analogous to those in
@racketmodname[racket/base] and @racketmodname[racket/list], except
that these forms support @tech{flows} in higher-order function
positions and leverage the @seclink["Don_t_Stop_Me_Now"]{stream fusion
/ deforestation} optimization to avoid constructing intermediate
representations along the way to computing the result.

The forms in this module extend the syntax of the
@seclink["The_Qi_Core_Language"]{core Qi language}. This extended
syntax is given below:

@racketgrammar*[
[floe (map floe)
      (filter floe)
      (filter-map floe)
      (foldl floe expr)
      (foldr floe expr)
      (range expr)
      (range expr expr)
      (range expr expr expr)
      (take expr)
      (filter-not floe)
      (list-tail expr)
      (drop expr)
      rest
      cdr
      cddr
      cdddr
      cddddr
      cdddddr
      car
      cadr
      caddr
      cadddr
      (list-ref expr)
      length
      empty?
      null?]]

The operations are categorized based on their role in the deforested
pipeline.

@section{Producers}

@defform[(build-list n proc)
	 #:contracts
	 ((n exact-nonnegative-integer?)
	  (proc (-> exact-nonnegative-integer? any/c)))]{

 Deforestable version of @racket[build-list] from @racketmodname[racket/base].

}

@defform[
 (make-list k v)
 #:contracts
 ((k exact-nonnegative-integer?)
  (v any/c))]{

 Deforestable version of @racket[make-list] from @racketmodname[racket/list].

}

@defform*[
  ((range end)
   (range start end)
   (range start end step))
  #:contracts
  ((start real?)
   (end real?)
   (step real?))]{

Deforestable version of @racket[range] from @racketmodname[racket/list].

By default @racket[start] is @racket[0] and @racket[step] is @racket[1].

}

@section{Transformers}


@defidform[cdr]{

Deforestable version of @racket[cdr] from @racketmodname[racket/base].

}

@defform*[
  ((list-tail pos)
   (drop pos))
  #:contracts
  ((pos exact-nonnegative-integer?))]{

Deforestable version of @racket[list-tail]/@racket[drop] from
@racketmodname[racket/base].

}

@defform[
  (map proc)
  #:contracts
  ((proc (-> any/c any/c)))]{

Deforestable version of @racket[map] from
@racketmodname[racket/base]. Note that, unlike the Racket version,
this accepts only one argument. For the "zip"-like behavior with
multiple list inputs, see @racket[△].

}

@defform[
  (filter pred)
  #:contracts
  ((pred (-> any/c any/c)))]{

Deforestable version of @racket[filter] from @racketmodname[racket/base].

}

@defform*[
 ((remove v)
  (remove v proc))
 #:contracts
 ((v any/c)
  (proc (-> any/c any/c)))]{

 Deforestable version of @racket[remove] from @racketmodname[racket/base].

}

@defform[
 (remq v)
 #:contracts
 ((v any/c))]{

 Deforestable version of @racket[remq] from @racketmodname[racket/base].

}

@defform[
 (remv v)
 #:contracts
 ((v any/c))]{

 Deforestable version of @racket[remv] from @racketmodname[racket/base].

}

@defform[
 (remw v)
 #:contracts
 ((v any/c))]{

 Deforestable version of @racket[remw] from @racketmodname[racket/base].

}

@defform*[
 ((remove* v)
  (remove* v proc))
 #:contracts
 ((v any/c)
  (proc (-> any/c any/c)))]{

 Deforestable version of @racket[remove*] from @racketmodname[racket/base].

}

@defform[
 (remq* v)
 #:contracts
 ((v any/c))]{

 Deforestable version of @racket[remq*] from @racketmodname[racket/base].

}

@defform[
 (remv* v)
 #:contracts
 ((v any/c))]{

 Deforestable version of @racket[remv*] from @racketmodname[racket/base].

}

@defform[
 (remw* v)
 #:contracts
 ((v any/c))]{

 Deforestable version of @racket[remw*] from @racketmodname[racket/base].

}

@defform*[
 ((member v)
  (member v proc))
 #:contracts
 ((v any/c)
  (proc (-> any/c any/c)))]{

 Deforestable version of @racket[member] from @racketmodname[racket/base].

}

@defform[
 (memq v)
 #:contracts
 ((v any/c))]{

 Deforestable version of @racket[memq] from @racketmodname[racket/base].

}

@defform[
 (memv v)
 #:contracts
 ((v any/c))]{

 Deforestable version of @racket[memv] from @racketmodname[racket/base].

}

@defform[
 (memw v)
 #:contracts
 ((v any/c))]{

 Deforestable version of @racket[memw] from @racketmodname[racket/base].

}

@defform[
 (memf proc)
 #:contracts
 ((proc (-> any/c any/c)))]{

 Deforestable version of @racket[memf] from @racketmodname[racket/base].

}

@defidform[cddr]{

Deforestable version of @racket[cddr] from @racketmodname[racket/base].

}

@defidform[cdddr]{

Deforestable version of @racket[cdddr] from @racketmodname[racket/base].

}

@defidform[cddddr]{

Deforestable version of @racket[cddddr] from @racketmodname[racket/base].

}

@defidform[rest]{

Deforestable version of @racket[rest] from @racketmodname[racket/list].

}

@defform[(list-update pos updater)
	 #:contracts
	 ((pos exact-nonnegative-integer?)
	  (updater (-> any/c any/c)))]{

 Deforestable version of @racket[list-update] from
 @racketmodname[racket/list].

}

@defform[(list-set pos value)
	 #:contracts
	 ((pos exact-nonnegative-integer?)
	  (value any/c))]{

 Deforestable version of @racket[list-set] from
 @racketmodname[racket/list].

}

@defform*[((indexes-of v is-equal?)
	   (indexes-of v))
	  #:contracts
	  ((v any/c)
	   (is-equal? (-> any/c any/c)))]{

 Deforestable version of @racket[indexes-of] from @racketmodname[racket/list].

}

@defform[(indexes-where proc)
	 #:contracts
	  ((proc (-> any/c any/c)))]{

 Deforestable version of @racket[indexes-where] from @racketmodname[racket/list].

}

@defform[
  (take pos)
  #:contracts
  ((pos exact-nonnegative-integer?))]{

Deforestable version of @racket[take] from @racketmodname[racket/list].

}

@defform[
  (takef pred)
  #:contracts
  ((pred (-> any/c any/c)))]{

Deforestable version of @racket[takef] from @racketmodname[racket/list].

}

@defform[(dropf pred)
	 #:contracts
	 ((pred (-> any/c any/c)))]{

 Deforestable version of @racket[dropf] from
 @racketmodname[racket/list].

}

@defform[
  (filter-map proc)
  #:contracts
  ((proc (-> any/c any/c)))]{

Deforestable version of @racket[filter-map] from @racketmodname[racket/list].

}

@defform[
  (filter-not pred)
  #:contracts
  ((pred (-> any/c any/c)))]{

Deforestable version of @racket[filter-not] from @racketmodname[racket/list].

}

@defform[(remf pred)
	 #:contracts
	 ((pred (-> any/c any/c)))]{

 Deforestable version of @racket[remf] from @racketmodname[racket/list].

}

@defform[(remf* pred)
	 #:contracts
	 ((pred (-> any/c any/c)))]{

 Deforestable version of @racket[remf*] from @racketmodname[racket/list].

}

@section{Consumers}

@defidform[pair?]{

 Deforestable version of @racket[pair?] from @racketmodname[racket/base].

}

@defidform[null?]{

Deforestable version of @racket[null?] from @racketmodname[racket/base].

}

@defidform[car]{

Deforestable version of @racket[car] from @racketmodname[racket/base].

}

@defidform[length]{

Deforestable version of @racket[length] from @racketmodname[racket/base].

}

@defform[
  (list-ref pos)
  #:contracts
  ((pos exact-nonnegative-integer?))]{

Deforestable version of @racket[list-ref] from @racketmodname[racket/base].

}

@defidform[reverse]{

 Deforestable version of @racket[reverse] from @racketmodname[racket/base].
}

@defform[
  (foldl proc init)
  #:contracts
  ((proc (-> any/c any/c any/c any/c))
   (init any/c))]{

Deforestable version of @racket[foldl] from @racketmodname[racket/base].

}

@defform[
  (foldr proc init)
  #:contracts
  ((proc (-> any/c any/c any/c any/c))
   (init any/c))]{

Deforestable version of @racket[foldr] from @racketmodname[racket/base].

}

@defform[(findf proc)
	 #:contracts
	 ((proc (-> any/c any/c)))]{

 Deforestable version of @racket[findf] from @racketmodname[racket/base].
				    
}

@defform*[((assoc v)
	   (assoc v is-equal?))
	  #:contracts
	  ((v any/c)
	   (is-equal? (-> any/c any/c)))]{

 Deforestable version of @racket[assoc] from @racketmodname[racket/base].
				    
}

@defform[(assw v)
	  #:contracts
	  ((v any/c))]{

 Deforestable version of @racket[assw] from @racketmodname[racket/base].
				    
}

@defform[(assv v)
	  #:contracts
	  ((v any/c))]{

 Deforestable version of @racket[assv] from @racketmodname[racket/base].
				    
}

@defform[(assq v)
	  #:contracts
	  ((v any/c))]{

 Deforestable version of @racket[assq] from @racketmodname[racket/base].
				    
}

@defform[(assf proc)
	  #:contracts
	  ((v (-> any/c any/c)))]{

 Deforestable version of @racket[assf] from @racketmodname[racket/base].
				    
}

@defidform[cadr]{

Deforestable version of @racket[cadr] from @racketmodname[racket/base].

}

@defidform[caddr]{

Deforestable version of @racket[caddr] from @racketmodname[racket/base].

}

@defidform[cadddr]{

Deforestable version of @racket[cadddr] from @racketmodname[racket/base].

}

@defidform[cons?]{

 Deforestable version of @racket[cons?] from @racketmodname[racket/list].

}

@defidform[empty?]{

Deforestable version of @racket[empty?] from @racketmodname[racket/list].

}

@defform*[((index-of v)
	   (index-of v is-equal?))
	  #:contracts
	  ((v any/c)
	   (is-equal? (-> any/c any/c)))]{

 Deforestable version of @racket[index-of] from @racketmodname[racket/list].

}

@defform[(index-where proc)
	 #:contracts
	 ((proc (-> any/c any/c)))]{

 Deforestable version of @racket[index-where] from @racketmodname[racket/list].

}

@defform[(argmin proc)
	 #:contracts
	 ((proc (-> any/c real?)))]{

 Deforestable version of @racket[argmin] from @racketmodname[racket/list].

}

@defform[(argmax proc)
	 #:contracts
	 ((proc (-> any/c real?)))]{

 Deforestable version of @racket[argmax] from @racketmodname[racket/list].

}
