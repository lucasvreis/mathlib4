/-
Copyright (c) 2016 Jeremy Avigad. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jeremy Avigad

! This file was ported from Lean 3 source module data.int.dvd.pow
! leanprover-community/mathlib commit e8638a0fcaf73e4500469f368ef9494e495099b3
! Please do not edit these lines, except to modify the commit id
! if you have ported upstream changes.
-/
import Mathlib.Data.Int.Dvd.Basic
import Mathlib.Data.Nat.Pow

/-!
# Basic lemmas about the divisibility relation in `ℤ` involving powers.
-/


open Nat

namespace Int

set_option linter.deprecated false in
@[simp]
theorem sign_pow_bit1 (k : ℕ) : ∀ n : ℤ, n.sign ^ bit1 k = n.sign
  | (_ + 1 : ℕ) => one_pow (bit1 k)
  | 0 => zero_pow (Nat.zero_lt_bit1 k)
  | -[_+1] => (neg_pow_bit1 1 k).trans (congr_arg (fun x => -x) (one_pow (bit1 k)))
#align int.sign_pow_bit1 Int.sign_pow_bit1

--TODO: Do we really need this lemma?
theorem pow_dvd_of_le_of_pow_dvd {p m n : ℕ} {k : ℤ} (hmn : m ≤ n) (hdiv : ↑(p ^ n) ∣ k) :
    ↑(p ^ m) ∣ k :=
  (pow_dvd_pow _ hmn).natCast.trans hdiv
#align int.pow_dvd_of_le_of_pow_dvd Int.pow_dvd_of_le_of_pow_dvd

theorem dvd_of_pow_dvd {p k : ℕ} {m : ℤ} (hk : 1 ≤ k) (hpk : ↑(p ^ k) ∣ m) : ↑p ∣ m :=
  (dvd_pow_self _ <| pos_iff_ne_zero.1 hk).natCast.trans hpk
#align int.dvd_of_pow_dvd Int.dvd_of_pow_dvd

end Int
