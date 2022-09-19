; authors: hrkrshnn, leonardoalt
; prove that combined staking is always at least as good as staking goo into separate gobblers
; should be unsat

(define-fun sqrt2 ((n Real) (r Real)) Bool
	(= n (* r r))
)

(define-fun delta_s ((m Real) (t Real) (s Real) (sqr Real) (res Real)) Bool
	(and
		(sqrt2 (* s m) sqr)
		(=
			res
			(+
				(*
					(/ 1 4)
					m
					(* t t)
				)
				(* sqr t)
			)
		)
	)
)

(define-fun delta_s_comb ((m1 Real) (m2 Real) (t Real) (s1 Real) (s2 Real) (sqr Real) (res Real)) Bool
	(and
		(sqrt2 (* (+ s1 s2) (+ m1 m2)) sqr)
		(=
			res
			(+
				(*
					(/ 1 4)
					(+ m1 m2)
					(* t t)
				)
				(* sqr t)
			)
		)
	)
)

(declare-const t Real)
(declare-const s1 Real)
(declare-const s2 Real)
(declare-const m1 Real)
(declare-const m2 Real)

(declare-const ds_1 Real)
(declare-const ds_2 Real)
(declare-const ds_comb Real)

(declare-const sqr_1 Real)
(declare-const sqr_2 Real)
(declare-const sqr_3 Real)

(assert (and
         (>= t 0)
         (>= s1 0)
         (>= s2 0)
         (>= m1 0)
         (>= m2 0)
         (>= sqr_1 0)
         (>= sqr_2 0)
         (>= sqr_3 0)
))

(assert (and
	(delta_s m1 t s1 sqr_1 ds_1)
	(delta_s m2 t s2 sqr_2 ds_2)
	(delta_s_comb m1 m2 t s1 s2 sqr_3 ds_comb)
))

(assert
	(< ds_comb (+ ds_1 ds_2))
)

(check-sat)