import Mathlib.Tactic.Convert
import Std.Tactic.GuardExpr
import Mathlib.Algebra.Group.Basic
import Mathlib.Data.Set.Image

example (P : Prop) (h : P) : P := by convert h

example (α β : Type) (h : α = β) (b : β) : α := by
  convert b

example (α β : Type) (h : ∀ α β : Type, α = β) (b : β) : α := by
  convert b
  apply h

example (m n : Nat) (h : m = n) (b : Fin n) : Nat × Nat × Nat × Fin m := by
  convert (37, 57, 2, b)

example (α β : Type) (h : α = β) (b : β) : Nat × α := by
  convert (config := { typeEqs := true }) (37, b)

example (α β : Type) (h : β = α) (b : β) : Nat × α := by
  convert (config := { typeEqs := true }) ← (37, b)

example (α β : Type) (h : α = β) (b : β) : Nat × Nat × Nat × α := by
  convert (config := { typeEqs := true }) (37, 57, 2, b)

example (α β : Type) (h : α = β) (b : β) : Nat × Nat × Nat × α := by
  convert (config := { typeEqs := true }) (37, 57, 2, b) using 2
  guard_target = (Nat × α) = (Nat × β)
  congr

example (α β : Type) (h : α = β) (b : β) : Nat × Nat × Nat × α := by
  convert (config := { typeEqs := true }) (37, 57, 2, b)

example {f : β → α} {x y : α} (h : x ≠ y) : f ⁻¹' {x} ∩ f ⁻¹' {y} = ∅ :=
by
  have : {x} ∩ {y} = (∅ : Set α) := by simpa [ne_comm] using h
  convert Set.preimage_empty
  rw [←Set.preimage_inter, this]

section convert_to

example {α} [AddCommMonoid α] {a b c d : α} (H : a = c) (H' : b = d) : a + b = d + c := by
  convert_to c + d = _ using 2
  rw [add_comm]

example {α} [AddCommMonoid α] {a b c d : α} (H : a = c) (H' : b = d) : a + b = d + c := by
  convert_to c + d = _ -- defaults to `using 1`
  congr 2
  rw [add_comm]

-- Check that `using 1` gives the same behavior as the default.
example {α} [AddCommMonoid α] {a b c d : α} (H : a = c) (H' : b = d) : a + b = d + c := by
  convert_to c + d = _ using 1
  congr 2
  rw [add_comm]

end convert_to

example (prime : Nat → Prop) (n : Nat) (h : prime (2 * n + 1)) :
    prime (n + n + 1) := by
  convert h
  · guard_target = (HAdd.hAdd : Nat → Nat → Nat) = HMul.hMul
    sorry
  · guard_target = n = 2
    sorry

example (prime : Nat → Prop) (n : Nat) (h : prime (2 * n + 1)) :
    prime (n + n + 1) := by
  convert (config := .unfoldSameFun) h
  guard_target = n + n = 2 * n
  sorry
