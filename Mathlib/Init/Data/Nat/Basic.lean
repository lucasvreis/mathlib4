/-
Copyright (c) 2014 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Floris van Doorn, Leonardo de Moura
-/
import Mathlib.Init.ZeroOne
import Mathlib.Init.Data.Nat.Notation

namespace Nat


section recursor_workarounds

/-- A computable version of `Nat.rec`. Workaround until Lean has native support for this. -/
def recC.{u} {motive : ℕ → Sort u} (zero : motive zero)
  (succ : (n : ℕ) → motive n → motive (succ n)) :
  (t : ℕ) → motive t
| 0 => zero
| (n + 1) => succ n (recC zero succ n)

@[csimp]
theorem rec_eq_recC : @Nat.rec = @Nat.recC := by
  funext motive zero succ n
  induction n with
  | zero => rfl
  | succ n ih => rw [Nat.recC, ←ih]

end recursor_workarounds

set_option linter.deprecated false

protected theorem bit0_succ_eq (n : ℕ) : bit0 (succ n) = succ (succ (bit0 n)) :=
  show succ (succ n + n) = succ (succ (n + n)) from congrArg succ (succ_add n n)
#align nat.bit0_succ_eq Nat.bit0_succ_eq

protected theorem zero_lt_bit0 : ∀ {n : Nat}, n ≠ 0 → 0 < bit0 n
  | 0, h => absurd rfl h
  | succ n, _ =>
    calc
      0 < succ (succ (bit0 n)) := zero_lt_succ _
      _ = bit0 (succ n) := (Nat.bit0_succ_eq n).symm

#align nat.zero_lt_bit0 Nat.zero_lt_bit0

protected theorem zero_lt_bit1 (n : Nat) : 0 < bit1 n :=
  zero_lt_succ _
#align nat.zero_lt_bit1 Nat.zero_lt_bit1

protected theorem bit0_ne_zero : ∀ {n : ℕ}, n ≠ 0 → bit0 n ≠ 0
  | 0, h => absurd rfl h
  | n + 1, _ =>
    suffices n + 1 + (n + 1) ≠ 0 from this
    suffices succ (n + 1 + n) ≠ 0 from this
    fun h => Nat.noConfusion h
#align nat.bit0_ne_zero Nat.bit0_ne_zero

protected theorem bit1_ne_zero (n : ℕ) : bit1 n ≠ 0 :=
  show succ (n + n) ≠ 0 from fun h => Nat.noConfusion h
#align nat.bit1_ne_zero Nat.bit1_ne_zero

end Nat

