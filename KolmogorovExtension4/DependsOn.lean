/-
Copyright (c) 2024 Etienne Marion. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Etienne Marion
-/

import Mathlib.Data.Finset.Update
import Mathlib.Data.Set.Basic
import Mathlib.MeasureTheory.Integral.Marginal
import Mathlib.Order.Restriction

/-!
# Functions depending only on some variables

When dealing with a function `f : Π i, α i` depending on many variables, some operations
may get rid of the dependency on some variables
(see `Function.updateFinset` or `lmarginal` for example). However considering this new function
as having a different domain with fewer points is not comfortable in Lean, as it requires the use
of subtypes and can lead to tedious writing.
On the other hand one wants to be able for example to call some function constant with respect to
some variables and be able to infer this when applying transformations mentioned above.
This is why introduce the predicate `DependsOn f s`, which states that if `x` and `y` coincide over
the set `s`, then `f x = f y`. This is then used to prove some properties about lmarginals.

## Main definitions

* `DependsOn f s`: If `x` and `y` coincide over the set `s`, then `f x` equals `f y`.

## Main statements

* `dependsOn_lmarginal`: If a function `f` depends on a set `s` and `t` is a finite set, then
  `∫⋯∫⁻_t, f ∂μ` depends on `s \ t`.
* `lmarginal_eq_of_disjoint`: If a function `f` depends on a set `s` and `t` is a finite set
  disjoint from `s` and the measures `μ i` are probability measures,
  then `∫⋯∫⁻_t, f ∂μ` is equal to `f`.

## Tags

depends on, updateFinset, update, lmarginal
-/

open MeasureTheory ENNReal Set Finset symmDiff Preorder

variable {ι : Type*} {α : ι → Type*} {β : Type*}

/-- A function `f` depends on `s` if, whenever `x` and `y` coincide over `s`, `f x = f y`. -/
def DependsOn (f : (Π i, α i) → β) (s : Set ι) : Prop :=
  ∀ ⦃x y⦄, (∀ i ∈ s, x i = y i) → f x = f y

lemma dependsOn_iff_factorsThrough {f : (Π i, α i) → β} {s : Set ι} :
    DependsOn f s ↔ Function.FactorsThrough f s.restrict := by
  rw [DependsOn, Function.FactorsThrough]
  congrm ∀ x y, ?_ → _
  simp [funext_iff]

theorem dependsOn_univ (f : (Π i, α i) → β) : DependsOn f univ :=
  fun _ _ h ↦ congrArg _ <| funext fun i ↦ h i trivial

variable {f : (Π i, α i) → β}

/-- A constant function does not depend on any variable. -/
theorem dependsOn_const (b : β) : DependsOn (fun _ : Π i, α i ↦ b) ∅ := by simp [DependsOn]

lemma DependsOn.mono {s t : Set ι} (hst : s ⊆ t) (hf : DependsOn f s) : DependsOn f t :=
  fun _ _ h ↦ hf fun i hi ↦ h i (hst hi)

/-- A function which depends on the empty set is constant. -/
theorem dependsOn_empty (hf : DependsOn f ∅) (x y : Π i, α i) : f x = f y := hf (by simp)

theorem Set.dependsOn_restrict (s : Set ι) : DependsOn (s.restrict (π := α)) s :=
  fun _ _ h ↦ funext fun i ↦ h i.1 i.2

theorem Finset.dependsOn_restrict (s : Finset ι) : DependsOn (s.restrict (π := α)) s :=
  (s : Set ι).dependsOn_restrict

theorem Preorder.dependsOn_restrictLe [Preorder ι] (i : ι) :
    DependsOn (restrictLe (π := α) i) (Set.Iic i) := (Iic i).dependsOn_restrict

theorem Preorder.dependsOn_frestrictLe [Preorder ι] [LocallyFiniteOrderBot ι] (i : ι) :
    DependsOn (frestrictLe (π := α) i) (Set.Iic i) := by
  convert (Finset.Iic i).dependsOn_restrict
  norm_cast

variable [DecidableEq ι]

/-- If one replaces the variables indexed by a finite set `t`, then `f` no longer depends on
these variables. -/
theorem DependsOn.updateFinset {s : Set ι} (hf : DependsOn f s) {t : Finset ι} (y : (i : t) → α i) :
    DependsOn (fun x ↦ f (Function.updateFinset x t y)) (s \ t) := by
  refine fun x₁ x₂ h ↦ hf (fun i hi ↦ ?_)
  simp only [Function.updateFinset]
  split_ifs with h'
  · rfl
  · simp_all

/-- If one replaces the variable indexed by `i`, then `f` no longer depends on
this variable. -/
theorem DependsOn.update {s : Finset ι} (hf : DependsOn f s) (i : ι) (y : α i) :
    DependsOn (fun x ↦ f (Function.update x i y)) (s.erase i) := by
  simp_rw [Function.update_eq_updateFinset, erase_eq, coe_sdiff]
  exact hf.updateFinset _

variable {X : ι → Type*} [∀ i, MeasurableSpace (X i)]
variable {μ : (i : ι) → Measure (X i)} {f : ((i : ι) → X i) → ℝ≥0∞} {s : Set ι}

/-- If a function depends on `s`, then its `lmarginal` with respect to a finite set `t` only
depends on `s \ t`. -/
theorem DependsOn.lmarginal (hf : DependsOn f s) (t : Finset ι) :
    DependsOn (∫⋯∫⁻_t, f ∂μ) (s \ t) :=
  fun _ _ h ↦ lintegral_congr fun z ↦ hf.updateFinset z h

variable [∀ i, IsProbabilityMeasure (μ i)]

/-- If `μ` is a family of probability measures, and `f` depends on `s`, then integrating over
some variables which are not in `s` does not change the value. -/
theorem lmarginal_eq_of_disjoint (hf : DependsOn f s) {t : Finset ι} (hst : Disjoint s t) :
    ∫⋯∫⁻_t, f ∂μ = f := by
  ext x
  have aux y : f (Function.updateFinset x t y) = f x := by
    refine hf (fun i hi ↦ ?_)
    simp [Function.updateFinset, mem_coe.not.1 <| hst.not_mem_of_mem_left hi]
  simp [lmarginal, lintegral_congr aux]

/-- Integrating a constant over some variables with respect to probability measures does nothing. -/
theorem lmarginal_const {s : Finset ι} (c : ℝ≥0∞) (x : (i : ι) → X i) :
    (∫⋯∫⁻_s, (fun _ ↦ c) ∂μ) x = c := by
  rw [lmarginal_eq_of_disjoint (dependsOn_const c) (empty_disjoint _)]

/-- If `μ` is a family of probability measures, and `f` depends on `s`, then integrating over
two different sets of variables such that their difference is not in `s`
yields the same function. -/
theorem lmarginal_eq_of_disjoint_diff (mf : Measurable f) (hf : DependsOn f s) {t u : Finset ι}
(htu : t ⊆ u) (hsut : Disjoint s (u \ t)) :
    ∫⋯∫⁻_u, f ∂μ = ∫⋯∫⁻_t, f ∂μ := by
  rw [← coe_sdiff] at hsut
  rw [← union_sdiff_of_subset htu, lmarginal_union _ _ mf disjoint_sdiff_self_right]
  congrm ∫⋯∫⁻_t, ?_ ∂μ
  exact lmarginal_eq_of_disjoint hf hsut

/-- If `μ` is a family of probability measures, and `f` depends on `s`, then integrating over
two different sets of variables such that their difference is not in `s`
yields the same function. -/
theorem lmarginal_eq_of_disjoint_symmDiff (mf : Measurable f) (hf : DependsOn f s)
    {t u : Finset ι} (hstu : Disjoint s (t ∆ u)) :
    ∫⋯∫⁻_t, f ∂μ = ∫⋯∫⁻_u, f ∂μ := by
  rw [symmDiff_def, disjoint_sup_right] at hstu
  obtain ⟨h1, h2⟩ := hstu
  rw [← coe_sdiff] at h1 h2
  have : ∫⋯∫⁻_u ∪ t, f ∂μ = ∫⋯∫⁻_u, f ∂μ := by
    rw [← union_sdiff_self_eq_union, lmarginal_union _ _ mf disjoint_sdiff_self_right]
    congrm ∫⋯∫⁻_u, ?_ ∂μ
    exact lmarginal_eq_of_disjoint hf h1
  rw [← this, Finset.union_comm, ← union_sdiff_self_eq_union,
    lmarginal_union _ _ mf disjoint_sdiff_self_right]
  congrm ∫⋯∫⁻_t, ?_ ∂μ
  exact (lmarginal_eq_of_disjoint hf h2).symm
