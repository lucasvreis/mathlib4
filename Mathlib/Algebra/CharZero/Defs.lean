/-
Copyright (c) 2014 Mario Carneiro. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Mario Carneiro

! This file was ported from Lean 3 source module algebra.char_zero.defs
! leanprover-community/mathlib commit d6aae1bcbd04b8de2022b9b83a5b5b10e10c777d
! Please do not edit these lines, except to modify the commit id
! if you have ported upstream changes.
-/
import Mathlib.Data.Int.Cast.Defs
import Mathlib.Tactic.NormCast.Tactic

/-!

# Characteristic zero

A ring `R` is called of characteristic zero if every natural number `n` is non-zero when considered
as an element of `R`. Since this definition doesn't mention the multiplicative structure of `R`
except for the existence of `1` in this file characteristic zero is defined for additive monoids
with `1`.

## Main definition

`CharZero` is the typeclass of an additive monoid with one such that the natural homomorphism
from the natural numbers into it is injective.

## TODO

* Unify with `CharP` (possibly using an out-parameter)
-/

/-- Typeclass for monoids with characteristic zero.
  (This is usually stated on fields but it makes sense for any additive monoid with 1.)
*Warning*: for a semiring `R`, `CharZero R` and `CharP R 0` need not coincide.
* `CharZero R` requires an injection `ℕ ↪ R`;
* `CharP R 0` asks that only `0 : ℕ` maps to `0 : R` under the map `ℕ → R`.
For instance, endowing `{0, 1}` with addition given by `max` (i.e. `1` is absorbing), shows that
`CharZero {0, 1}` does not hold and yet `CharP {0, 1} 0` does.
This example is formalized in `counterexamples/char_p_zero_ne_char_zero`.
 -/
class CharZero (R) [AddMonoidWithOne R] : Prop where
  /-- An additive monoid with one has characteristic zero if the canonical map `ℕ → R` is
  injective. -/
  cast_injective : Function.Injective (Nat.cast : ℕ → R)
#align char_zero CharZero

theorem charZero_of_inj_zero [AddGroupWithOne R] (H : ∀ n : ℕ, (n : R) = 0 → n = 0) :
    CharZero R :=
  ⟨@fun m n h => by
    induction' m with m ih generalizing n
    · rw [H n]
      rw [← h, Nat.cast_zero]

    cases' n with n
    · apply H
      rw [h, Nat.cast_zero]

    simp only [Nat.cast_succ, add_right_cancel_iff] at h
    rwa [ih]⟩
#align char_zero_of_inj_zero charZero_of_inj_zero

namespace Nat

variable [AddMonoidWithOne R] [CharZero R]

theorem cast_injective : Function.Injective (Nat.cast : ℕ → R) :=
  CharZero.cast_injective
#align nat.cast_injective Nat.cast_injective

@[simp, norm_cast]
theorem cast_inj {m n : ℕ} : (m : R) = n ↔ m = n :=
  cast_injective.eq_iff
#align nat.cast_inj Nat.cast_inj

@[simp, norm_cast]
theorem cast_eq_zero {n : ℕ} : (n : R) = 0 ↔ n = 0 := by rw [← cast_zero, cast_inj]
#align nat.cast_eq_zero Nat.cast_eq_zero

@[norm_cast]
theorem cast_ne_zero {n : ℕ} : (n : R) ≠ 0 ↔ n ≠ 0 :=
  not_congr cast_eq_zero
#align nat.cast_ne_zero Nat.cast_ne_zero

theorem cast_add_one_ne_zero (n : ℕ) : (n + 1 : R) ≠ 0 := by
  -- porting note: old proof was `exact_mod_cast n.succ_ne_zero`
  norm_cast
  exact n.succ_ne_zero
#align nat.cast_add_one_ne_zero Nat.cast_add_one_ne_zero

@[simp, norm_cast]
theorem cast_eq_one {n : ℕ} : (n : R) = 1 ↔ n = 1 := by rw [← cast_one, cast_inj]
#align nat.cast_eq_one Nat.cast_eq_one

@[norm_cast]
theorem cast_ne_one {n : ℕ} : (n : R) ≠ 1 ↔ n ≠ 1 :=
  cast_eq_one.not
#align nat.cast_ne_one Nat.cast_ne_one

end Nat

namespace OfNat

variable [AddMonoidWithOne R] [CharZero R]

@[simp] lemma ofNat_ne_zero (n : ℕ) [h : n.AtLeastTwo] : (ofNat n : R) ≠ 0 :=
  Nat.cast_ne_zero.2 <| ne_of_gt <| lt_trans Nat.one_pos h.prop

@[simp] lemma zero_ne_ofNat (n : ℕ) [n.AtLeastTwo] : 0 ≠ (ofNat n : R) :=
  (ofNat_ne_zero n).symm

@[simp] lemma ofNat_ne_one (n : ℕ) [h : n.AtLeastTwo] : (ofNat n : R) ≠ 1 := by
  rw [← Nat.cast_eq_ofNat, ← @Nat.cast_one R, Ne.def, Nat.cast_inj]
  exact ne_of_gt h.prop

@[simp] lemma one_ne_ofNat (n : ℕ) [n.AtLeastTwo] : (1 : R) ≠ ofNat n :=
  (ofNat_ne_one n).symm

@[simp] lemma ofNat_eq_ofNat {m n : ℕ} [m.AtLeastTwo] [n.AtLeastTwo] :
    (ofNat m : R) = ofNat n ↔ (ofNat m : ℕ) = ofNat n :=
  Nat.cast_inj

end OfNat

namespace NeZero

instance charZero {M} {n : ℕ} [NeZero n] [AddMonoidWithOne M] [CharZero M] : NeZero (n : M) :=
  ⟨Nat.cast_ne_zero.mpr out⟩
#align ne_zero.char_zero NeZero.charZero

instance charZero_ofNat {M} {n : ℕ} [n.AtLeastTwo] [AddMonoidWithOne M] [CharZero M] :
    NeZero (OfNat.ofNat n : M) :=
  ⟨OfNat.ofNat_ne_zero n⟩

end NeZero
