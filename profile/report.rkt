#lang cli

(require
 (prefix-in one-of?: (submod "forms.rkt" one-of?))
 (prefix-in and: (submod "forms.rkt" and))
 (prefix-in or: (submod "forms.rkt" or))
 (prefix-in not: (submod "forms.rkt" not))
 (prefix-in and%: (submod "forms.rkt" and%))
 (prefix-in or%: (submod "forms.rkt" or%))
 (prefix-in group: (submod "forms.rkt" group))
 (prefix-in count: (submod "forms.rkt" count))
 (prefix-in relay: (submod "forms.rkt" relay))
 (prefix-in relay*: (submod "forms.rkt" relay*))
 (prefix-in amp: (submod "forms.rkt" amp))
 (prefix-in ground: (submod "forms.rkt" ground))
 (prefix-in thread: (submod "forms.rkt" thread))
 (prefix-in thread-right: (submod "forms.rkt" thread-right))
 (prefix-in crossover: (submod "forms.rkt" crossover))
 (prefix-in all: (submod "forms.rkt" all))
 (prefix-in any: (submod "forms.rkt" any))
 (prefix-in none: (submod "forms.rkt" none))
 (prefix-in all?: (submod "forms.rkt" all?))
 (prefix-in any?: (submod "forms.rkt" any?))
 (prefix-in none?: (submod "forms.rkt" none?))
 (prefix-in collect: (submod "forms.rkt" collect))
 (prefix-in sep: (submod "forms.rkt" sep))
 (prefix-in gen: (submod "forms.rkt" gen))
 (prefix-in esc: (submod "forms.rkt" esc))
 (prefix-in AND: (submod "forms.rkt" AND))
 (prefix-in OR: (submod "forms.rkt" OR))
 (prefix-in NOT: (submod "forms.rkt" NOT))
 (prefix-in NAND: (submod "forms.rkt" NAND))
 (prefix-in NOR: (submod "forms.rkt" NOR))
 (prefix-in XOR: (submod "forms.rkt" XOR))
 (prefix-in XNOR: (submod "forms.rkt" XNOR))
 (prefix-in tee: (submod "forms.rkt" tee))
 (prefix-in try: (submod "forms.rkt" try))
 (prefix-in currying: (submod "forms.rkt" currying))
 (prefix-in template: (submod "forms.rkt" template))
 (prefix-in catchall-template: (submod "forms.rkt" catchall-template))
 (prefix-in if: (submod "forms.rkt" if))
 (prefix-in when: (submod "forms.rkt" when))
 (prefix-in unless: (submod "forms.rkt" unless))
 (prefix-in switch: (submod "forms.rkt" switch))
 (prefix-in sieve: (submod "forms.rkt" sieve))
 (prefix-in partition: (submod "forms.rkt" partition))
 (prefix-in gate: (submod "forms.rkt" gate))
 (prefix-in input-aliases: (submod "forms.rkt" input-aliases))
 (prefix-in fanout: (submod "forms.rkt" fanout))
 (prefix-in inverter: (submod "forms.rkt" inverter))
 (prefix-in feedback: (submod "forms.rkt" feedback))
 (prefix-in select: (submod "forms.rkt" select))
 (prefix-in block: (submod "forms.rkt" block))
 (prefix-in bundle: (submod "forms.rkt" bundle))
 (prefix-in effect: (submod "forms.rkt" effect))
 (prefix-in live?: (submod "forms.rkt" live?))
 (prefix-in rectify: (submod "forms.rkt" rectify))
 (prefix-in pass: (submod "forms.rkt" pass))
 (prefix-in foldl: (submod "forms.rkt" foldl))
 (prefix-in foldr: (submod "forms.rkt" foldr))
 (prefix-in loop: (submod "forms.rkt" loop))
 (prefix-in loop2: (submod "forms.rkt" loop2))
 (prefix-in apply: (submod "forms.rkt" apply))
 (prefix-in clos: (submod "forms.rkt" clos)))

(require racket/match
         racket/format
         relation
         qi
         json
         (only-in "util.rkt"
                  only-if
                  for/call))

;; It would be great if we could get the value of a variable
;; by using its (string) name, but (eval (string->symbol name))
;; doesn't find it. So instead, we reify the "lexical environment"
;; here manually, so that the values can be looked up at runtime
;; based on the string names (note that the value is always the key
;; + ":" + "run")
(define env
  (hash
   "one-of?" one-of?:run
   "and" and:run
   "or" or:run
   "not" not:run
   "and%" and%:run
   "or%" or%:run
   "group" group:run
   "count" count:run
   "relay" relay:run
   "relay*" relay*:run
   "amp" amp:run
   "ground" ground:run
   "thread" thread:run
   "thread-right" thread-right:run
   "crossover" crossover:run
   "all" all:run
   "any" any:run
   "none" none:run
   "all?" all?:run
   "any?" any?:run
   "none?" none?:run
   "collect" collect:run
   "sep" sep:run
   "gen" gen:run
   "esc" esc:run
   "AND" AND:run
   "OR" OR:run
   "NOT" NOT:run
   "NAND" NAND:run
   "NOR" NOR:run
   "XOR" XOR:run
   "XNOR" XNOR:run
   "tee" tee:run
   "try" try:run
   "currying" currying:run
   "template" template:run
   "catchall-template" catchall-template:run
   "if" if:run
   "when" when:run
   "unless" unless:run
   "switch" switch:run
   "sieve" sieve:run
   "partition" partition:run
   "gate" gate:run
   "input-aliases" input-aliases:run
   "fanout" fanout:run
   "inverter" inverter:run
   "feedback" feedback:run
   "select" select:run
   "block" block:run
   "bundle" bundle:run
   "effect" effect:run
   "live?" live?:run
   "rectify" rectify:run
   "pass" pass:run
   "foldl" foldl:run
   "foldr" foldr:run
   "loop" loop:run
   "loop2" loop2:run
   "apply" apply:run
   "clos" clos:run))

(program (main)
  (let* ([forms (hash-keys env)]
         [fs (~>> (forms)
                  (sort <))])
    (write-json (for/list ([f fs])
                  (match-let ([(list name ms) ((hash-ref env f))])
                    (hash 'name name 'unit "ms" 'value ms))))))

(run main)
