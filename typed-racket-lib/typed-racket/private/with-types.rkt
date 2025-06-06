#lang racket/base

(require "../utils/utils.rkt"
         "../base-env/base-types-extra.rkt"
         (except-in "../base-env/prims.rkt" with-handlers λ lambda define)
         "../env/type-name-env.rkt"
         "../env/type-alias-env.rkt"
         "../env/global-env.rkt"
         "parse-type.rkt"
         "type-contract.rkt"
         "syntax-properties.rkt"
         "../typecheck/tc-toplevel.rkt"
         "../typecheck/typechecker.rkt"
         "../types/utils.rkt"
         "../utils/lift.rkt"
         "../utils/tc-utils.rkt"
         "../utils/disarm.rkt"
         "../utils/arm.rkt"
         "../utils/literal-syntax-class.rkt"
         racket/promise
         racket/syntax
         syntax/flatten-begin
         syntax/parse
         racket/sequence
         "../tc-setup.rkt"
         "../standard-inits.rkt"
         (for-template
          (except-in racket/base for for* with-handlers with-handlers*
                     lambda λ define
                     let let* letrec letrec-values let-values let*-values
                     let/cc let/ec do case-lambda case-λ struct define-struct
                     default-continuation-prompt-tag
                     for/list for/vector for/hash for/hasheq for/hasheqv for/hashalw
                     for/and for/or for/sum for/product for/lists
                     for/first for/last for/fold for/foldr for*/list for*/lists
                     for*/vector for*/hash for*/hasheq for*/hasheqv for*/hashalw
                     for*/and
                     for*/or for*/sum for*/product for*/first for*/last
                     for*/fold for*/foldr)
          "../base-env/prims.rkt"
          (prefix-in c: racket/contract/region))
         (for-label racket/base
                    "../base-env/base-types-extra.rkt"))

(define-literal-syntax-class #:for-label Values)
(define-literal-syntax-class #:for-label values)

(provide wt-core wt-core-shallow wt-core-optional)

(define (with-type-helper stx body fvids fvtys exids extys resty expr? ctx te-mode)
  (define old-context (unbox typed-context?))
  (define old-te-mode (unbox type-enforcement-mode))
  (when old-context
    (tc-error/stx stx (format "with-type cannot be used in a typed module. ~a " old-context)))
  (set-box! typed-context? #t)
  (set-box! type-enforcement-mode te-mode)
  (do-standard-inits)
  (define fv-types (for/list ([t (in-syntax fvtys)])
                     (parse-type t)))
  (define ex-types (for/list ([t (in-syntax extys)])
                     (parse-type t)))
  (define-values (fv-ctc-ids fv-ctc-defs)
    (type-stxs->ids+defs (syntax->list fvtys) 'untyped te-mode))
  (define-values (ex-ctc-ids ex-ctc-defs)
    (type-stxs->ids+defs (syntax->list extys) 'typed te-mode))
  (define-values (region-ctc-ids region-ctc-defs)
    (if expr?
        (type-stxs->ids+defs (values-stx->type-stxs resty) 'typed te-mode)
        (values null null)))
  (define region-tc-result
    (and expr? (parse-tc-results resty)))
  (for ([i (in-syntax fvids)]
        [ty (in-list fv-types)])
    (register-type i ty))
  (define-values (lifted-definitions expanded-body)
    (if expr?
        (with-syntax ([body body])
          (wt-expand #'(let () . body) ctx))
        (with-syntax ([(body ...) body]
                      [(id ...) exids]
                      [(ty ...) extys])
          (wt-expand #'(let () (begin (: id ty) ... body ... (values id ...))) ctx))))
  (parameterize (;; do we report multiple errors
                 [delay-errors? #t]
                 ;; this parameter is just for printing types
                 ;; this is a parameter to avoid dependency issues
                 [current-type-names
                  (lazy
                    (append
                     (type-name-env-map (lambda (id ty)
                                          (cons (syntax-e id) ty)))
                     (type-alias-env-map (lambda (id ty)
                                           (cons (syntax-e id) ty)))))]
                 ;; reinitialize disappeared uses
                 [disappeared-use-todo      null]
                 [disappeared-bindings-todo null]
                 ;; for error reporting
                 [orig-module-stx stx]
                 [expanded-module-stx expanded-body])
    ;; we can treat the lifted definitions as top-level forms because they
    ;; are only definitions and not forms that have special top-level meaning
    ;; to TR
    (tc-toplevel-form lifted-definitions)
    (tc-expr/check expanded-body (if expr? region-tc-result (ret ex-types))))
  (set-box! typed-context? old-context)
  (set-box! type-enforcement-mode old-te-mode)
  ;; then clear the new entries from the env ht
  (for ([i (in-syntax fvids)])
    (unregister-type i))
  ;; report errors after setting the typed-context? flag and unregistering
  ;; types to ensure that the state is cleaned up properly in the REPL
  (report-all-errors)
  (set-box! type-enforcement-mode te-mode) ;; begin optimizer + contracts
  (with-syntax ([(fv.id ...) fvids]
                [(cnt ...) fv-ctc-ids]
                [(ex-id ...) exids]
                [(ex-cnt ...) ex-ctc-ids]
                [(region-cnt ...) region-ctc-ids]
                [(body) (parameterize ([optimize? (memq te-mode (list deep shallow))]) (maybe-optimize #`(#,expanded-body)))]
                [check-syntax-help (syntax-property
                                    (syntax-property
                                     #'(void)
                                     'disappeared-binding (disappeared-bindings-todo))
                                    'disappeared-use (disappeared-use-todo))])
    (define fixed-up-definitions
      (change-contract-fixups
       (flatten-all-begins
        #`(begin #,lifted-definitions
                 #,@(if expr? (append region-ctc-defs fv-ctc-defs) null)
                 #,@(if (not expr?) ex-ctc-defs null)))))
    (set-box! type-enforcement-mode old-te-mode) ;; end optimizer + contracts 
    (arm
      (if expr?
          (quasisyntax/loc stx
            (let ()
              check-syntax-help
              (local-require #,@(cdr (syntax-e extra-requires)))
              #,@fixed-up-definitions
              (c:with-contract typed-region
                               #:results (region-cnt ...)
                               #:freevars ([fv.id cnt] ...)
                               body)))
          (quasisyntax/loc stx
            (begin
              (local-require #,@(cdr (syntax-e extra-requires)))
              (define-values () (begin check-syntax-help (values)))
              #,@fixed-up-definitions
              (c:with-contract typed-region
                               ([ex-id ex-cnt] ...)
                               (define-values (ex-id ...) body))))))))

;; Syntax (U Symbol List) -> (values Syntax Syntax)
;; local expansion for with-type expressions
(define (wt-expand stx ctx)
  (syntax-parse (local-expand/capture* stx ctx null)
    #:literal-sets (kernel-literals)
    [(begin (define-values (x ...) e ...) ... (let-values () . body))
     (values (disarm* #'(begin (define-values (x ...) e ...) ...))
             (disarm* (local-expand/capture* #'(let-values () . body) ctx null)))]))

;; Deconstruct values type stx that the user wrote
(define (values-stx->type-stxs values-stx)
  (syntax-parse values-stx
    [((~or :Values^ :values^) t ...)
     (syntax->list #'(t ...))]
    [t (list #'t)]))

;; type-stxs->ids+defs : (Listof Syntax) Symbol type-enforcement-mode? -> (Listof Id Syntax)
;; Create identifiers and definition syntaxes for contract generation
(define (type-stxs->ids+defs type-stxs typed-side te-mode)
  (for/lists (_1 _2) ([t (in-list type-stxs)])
    (define ctc-id (generate-temporary))
    (define contract-def `#s(contract-def ,t #f #f ,typed-side ,te-mode))
    (values ctc-id
            #`(define-values (#,ctc-id)
                #,(contract-def-property
                   #'#f (λ () contract-def))))))

(define-values [wt-core wt-core-shallow wt-core-optional]
 (let ()
  (define-syntax-class typed-id
    #:description "[id type]"
    [pattern (id ty)])
  (define-splicing-syntax-class free-vars
    #:description "free variable specification"
    #:attributes ((id 1) (ty 1))
    [pattern (~seq #:freevars (:typed-id ...))]
    [pattern (~seq)
             #:with (id ...) null
             #:with (ty ...) null])
  (define-syntax-class typed-ids
    #:description "sequence of typed identifiers"
    #:attributes ((id 1) (ty 1))
    [pattern (t:typed-id ...)
             #:with (id ...) #'(t.id ...)
             #:with (ty ...) #'(t.ty ...)])
  (define-splicing-syntax-class result-ty
    #:description "result specification"
    [pattern (~seq #:result ty:expr)])
  (apply
    values
    (for/list ((te-mode (in-list (list deep shallow optional))))
      (syntax-parser
        [(_ :typed-ids fv:free-vars . body)
         (with-type-helper this-syntax #'body #'(fv.id ...) #'(fv.ty ...) #'(id ...) #'(ty ...) #f #f (syntax-local-context) te-mode)]
        [(_ :result-ty fv:free-vars . body)
         (with-type-helper this-syntax #'body #'(fv.id ...) #'(fv.ty ...) #'() #'() #'ty #t (syntax-local-context) te-mode)])))))
