#lang racket/base

(require "../utils/utils.rkt"
         (contract-req)
         racket/list
         racket/match
         "../rep/core-rep.rkt"
         "../rep/type-rep.rkt"
         "../rep/prop-rep.rkt"
         "../rep/values-rep.rkt"
         "../types/subtype.rkt"
         "../types/tc-result.rkt"
         (except-in "../types/abbrev.rkt"
                    -> ->* one-of/c))

(provide possible-domains)

(provide/cond-contract
  [cleanup-type ((Type?) ((or/c #f Type?) any/c) . ->* . Type?)])

;; to avoid long and confusing error messages, in the case of functions with
;; multiple similar domains (<, >, +, -, etc.), we show only the domains that
;; are relevant to this specific error
;; this is done in several ways:
;; - if a case-lambda case is subsumed by another, we don't need to show it
;;   (subsumed cases may be useful for their prop information, but this is
;;   unrelated to error reporting)
;; - if we have an expected type, we don't need to show the domains for which
;;   the result type is not a subtype of the expected type
;; - we can disregard domains that are more restricted than required to get
;;   the expected type (or all but the most liberal domain when no type is
;;   expected)
;;   ex: if we have the 2 following possible domains for an operator:
;;       Fixnum -> Fixnum
;;       Integer -> Integer
;;     and an expected type of Integer for the result of the application,
;;     we can disregard the Fixnum domain since it imposes a restriction that
;;     is not necessary to get the expected type
;; This function can be used in permissive or restrictive mode.
;; in permissive mode, domains that are not consistent with the expected type
;; may still be considered possible. This is useful for error messages, where
;; we want to collapse domains always, regardless of expected type. In
;; restrictive mode, only domains that are consistent with the expected type can
;; be considered possible. This is useful when computing the possibly empty set
;; of domains that would *satisfy* the expected type, e.g. for the :query-type
;; forms.
;; TODO separating pruning and collapsing into separate functions may be nicer
(define (possible-domains doms rests rngs expected [permissive? #t])

  ;; is fun-ty subsumed by a function type in others?
  (define (is-subsumed-in? fun-ty others)
    ;; a case subsumes another if the first one is a subtype of the other
    (ormap (lambda (x) (subtype x fun-ty))
           others))

  ;; currently does not take advantage of multi-valued or arbitrary-valued expected types,
  (define expected-ty
    (match expected
      [#f #f]
      [(tc-result1: t) t]
      [(tc-any-results: (or #f (TrueProp:))) #t] ; anything is a subtype of expected
      [_ #f])) ; don't know what it is, don't do any pruning
  (define (returns-subtype-of-expected? fun-ty)
    (or (not expected) ; no expected type, anything is fine
        (eq? expected-ty #t) ; expected is tc-anyresults, anything is fine
        (and expected-ty ; not some unknown expected tc-result
             (match fun-ty
               [(Fun: (list (Arrow: _ _ _ rng)))
                (let ([rng (match rng
                             [(Values: (list (Result: t _ _)))
                              t]
                             [(ValuesDots: (list (Result: t _ _)) _ _)
                              t]
                             [_ #f])])
                  (and rng (subtype rng expected-ty)))]))))

  (define orig (map list doms rngs rests))

  (define cases (for/list ([d (in-list doms)]
                           [rst (in-list rests)]
                           [rng (in-list rngs)])
                  (make-Fun (list (make-Arrow d rst null
                                              (match rng ; strip props from range
                                                [(AnyValues: f) (-AnyValues -tt)]
                                                [(Values: (list (Result: t _ _) ...))
                                                 (-values t)]
                                                [(ValuesDots: (list (Result: t _ _) ...) _ _)
                                                 (-values t)]) #f)))))

  ;; iterate in lock step over the function types we analyze and the parts
  ;; that we will need to print the error message, to make sure we throw
  ;; away cases consistently
  (define-values (candidates* parts-acc*)
    (for/fold ([candidates '()] ; from cases
               [parts-acc '()]) ; from orig
        ([c (in-list cases)]
         ;; the parts we'll need to print the error message
         [p (in-list orig)])
      (if (returns-subtype-of-expected? c)
          (values (cons c candidates) ; we keep this one
                  (cons p parts-acc))
          ;; we discard this one
          (values candidates parts-acc))))

  ;; if none of the cases return a subtype of the expected type, still do some
  ;; merging, but do it on the entire type
  ;; only do this if we're in permissive mode
  (define-values (candidates parts-acc)
    (if (and permissive? (null? candidates*))
        (values cases orig)
        (values candidates* parts-acc*)))

  ;; among the domains that fit with the expected type, we only need to
  ;; keep the most liberal
  ;; since we only care about permissiveness of domains, we reconstruct
  ;; function types with a return type of any then test for subtyping
  (define fun-tys-ret-any
    (map (match-lambda
          [(Fun: (list (Arrow: dom rst _ _)))
           (make-Fun (list (make-Arrow dom
                                       rst
                                       null
                                       (-values (list Univ)) #f)))])
         candidates))

  ;; Heuristic: often, the last case in the definition (first at this
  ;; point, we've reversed the list) is the most general of all, subsuming
  ;; all the others. If that's the case, just go with it. Otherwise, go
  ;; the slow way.
  (cond [(and (not (null? fun-tys-ret-any))
              (andmap (lambda (c) (subtype (car fun-tys-ret-any) c))
                      fun-tys-ret-any))
         ;; Yep. Return early.
         (map list (car parts-acc))]
        
        [else
         ;; No luck, do it the slow way
         (define parts-res
           ;; final pass, we only need the parts to print the error message
           (for/fold ([parts-res '()])
               ([c (in-list fun-tys-ret-any)]
                [p (in-list parts-acc)]
                ;; if a case is a supertype of another, we discard it
                #:unless (is-subsumed-in? c (remove c fun-tys-ret-any)))

             (cons p parts-res)))

         (call-with-values
           (λ ()
             (for/lists (_1 _2 _3) ([xs (in-list (reverse parts-res))])
               (values (car xs) (cadr xs) (caddr xs))))
           list)]))

;; Wrapper over possible-domains that works on types.
(define (cleanup-type t [expected #f] [permissive? #t])
  (match t
    ;; function type, prune if possible.
    [(Fun: (list (Arrow: doms rests _ rngs rngs-T+) ...))
     (match-let ([(list pdoms rngs rests)
                  (possible-domains doms rests rngs
                                    (and expected (ret expected))
                                    permissive?)])
       (if (= (length pdoms) (length doms))
           ;; pruning didn't improve things, return the original
           ;; (Note: pruning may have reordered clauses, so may not be `equal?' to
           ;;  the original, which may confuse `:print-type''s pruning detection)
           t
           ;; pruning helped, return pruned type
           (make-Fun (for/list ([pdom (in-list pdoms)]
                                [rst (in-list rests)]
                                [rng (in-list rngs)]
                                [T+ (in-list rngs-T+)])
                       (make-Arrow pdom rst null rng T+)))))]
    ;; not a function type. keep as is.
    [_ t]))
