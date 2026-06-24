# Pathogen Classifier

ML-based viral genome classifier for Infectious diseases in Africa

> ⚠️ **Under active rework — OpenViroTax-Africa (June 2026).** This project is
> being rebuilt as **OpenViroTax**: a *confidence-calibrated, abstaining,
> fragment-aware* viral-family classifier. We pivoted from the original
> TensorFlow/CNN plan to a **scikit-learn** pipeline so the focus can be on the
> research contribution — knowing *when not to trust* a prediction — rather than
> heavy model training.
>
> **Pipeline:** NCBI RefSeq genomes (7 families) → length-weighted fragmentation
> (250/500/1000 bp contigs) → k-mer + GC features → calibrated classifier →
> conformal abstention → leave-one-family-out novelty detection.
>
> **Progress so far:** 730 genomes downloaded; 46k fragments; k-mer features;
> calibrated Random Forest (Expected Calibration Error improved ~3×, 0.23 → 0.075).
> Abstention, novelty detection, and the benchmark are in progress.
>
> Full plan: [`.claude/plans/woolly-imagining-swan.md`](../../../.claude/plans/woolly-imagining-swan.md).



## License

MIT License - see LICENSE file for details.

## Author

Joshua Ampofo Yentumi (ampofojoshuayent@gmail.com)

---

*Last updated: June 24, 2026*